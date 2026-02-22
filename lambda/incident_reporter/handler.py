import os
import json
import time
import uuid
import datetime

import boto3
import botocore

logs = boto3.client("logs")
ssm = boto3.client("ssm")
secrets = boto3.client("secretsmanager")
s3 = boto3.client("s3")
sns = boto3.client("sns")
bedrock = boto3.client("bedrock-runtime")

# Required env vars (Terraform must set these)
REPORT_BUCKET = os.environ["REPORT_BUCKET"]
APP_LOG_GROUP = os.environ["APP_LOG_GROUP"]
WAF_LOG_GROUP = os.environ["WAF_LOG_GROUP"]
SECRET_ID = os.environ["SECRET_ID"]
SSM_PARAM_PATH = os.environ["SSM_PARAM_PATH"]

MODEL_PRIMARY = os.environ["BEDROCK_MODEL_ID_PRIMARY"]
MODEL_FALLBACK = os.environ["BEDROCK_MODEL_ID_FALLBACK"]

SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]

REPORT_PREFIX = os.environ.get("REPORT_PREFIX", "reports")
FAST_WINDOW_MINUTES = int(os.environ.get("FAST_WINDOW_MINUTES", "15"))


# Alarm parsing (required pattern)
def parse_alarm_event(event):
    # SNS wrapped?
    if "Records" in event and event["Records"] and "Sns" in event["Records"][0]:
        msg = event["Records"][0]["Sns"].get("Message", "")
        try:
            return json.loads(msg)
        except json.JSONDecodeError:
            return {"raw_message": msg}
    return event


def safe_alarm_fields(alarm_payload: dict) -> dict:
    # Work with real CW alarms OR fake harness payload
    return {
        "name": alarm_payload.get("AlarmName") or alarm_payload.get("alarmName") or alarm_payload.get("name") or "Unknown",
        "metric": alarm_payload.get("MetricName") or alarm_payload.get("metric") or "Unknown",
        "threshold": alarm_payload.get("Threshold") or alarm_payload.get("threshold") or "Unknown",
        "state": alarm_payload.get("NewStateValue") or alarm_payload.get("state") or "Unknown",
    }


def iso_utc_z(ts: datetime.datetime) -> str:
    return ts.replace(microsecond=0, tzinfo=datetime.timezone.utc).isoformat().replace("+00:00", "Z")


# CloudWatch Logs Insights
def run_insights_query(log_group: str, query: str, start_ts: int, end_ts: int, limit: int = 100):
    qid = logs.start_query(
        logGroupName=log_group,
        startTime=start_ts,
        endTime=end_ts,
        queryString=query,
        limit=limit,
    )["queryId"]

    for _ in range(30):
        resp = logs.get_query_results(queryId=qid)
        status = resp.get("status")
        if status in ("Complete", "Failed", "Cancelled", "Timeout"):
            return {"status": status, "queryId": qid, "results": resp.get("results", [])}
        time.sleep(1.0)

    return {"status": "Timeout", "queryId": qid, "results": []}


# Evidence collection (SSM + Secrets)
def get_ssm_params_safe(path: str):
    """
    Contract requirement: include endpoint/port/name.
    This function returns values for known safe keys under the path.
    """
    wanted_suffixes = ("/endpoint", "/port", "/name", "/dbname")
    found = {}
    next_token = None

    while True:
        kwargs = {"Path": path, "Recursive": True, "WithDecryption": False}
        if next_token:
            kwargs["NextToken"] = next_token

        resp = ssm.get_parameters_by_path(**kwargs)
        for p in resp.get("Parameters", []):
            n = p.get("Name", "")
            v = p.get("Value", "")
            if n.endswith(wanted_suffixes):
                found[n] = v

        next_token = resp.get("NextToken")
        if not next_token:
            break

    # Normalize per handout
    normalized = {
        "endpoint": found.get(path.rstrip("/") + "/endpoint") or found.get(path.rstrip("/") + "/host"),
        "port": found.get(path.rstrip("/") + "/port"),
        "name": found.get(path.rstrip("/") + "/name") or found.get(path.rstrip("/") + "/dbname"),
    }

    return {"normalized": normalized, "raw_safe_subset": found}


def get_secret_meta(secret_id: str):
    """
    Contract requirement: host/port/dbname/username only — no password.
    """
    try:
        raw = secrets.get_secret_value(SecretId=secret_id).get("SecretString", "{}")
        payload = json.loads(raw) if raw else {}
        return {
            "host": payload.get("host", "Unknown"),
            "port": payload.get("port", "Unknown"),
            "dbname": payload.get("dbname", "Unknown"),
            "username": payload.get("username", "Unknown"),
        }
    except Exception as e:
        return {"host": "Unknown", "port": "Unknown", "dbname": "Unknown", "username": "Unknown", "error": str(e)}


# Model family detection
def model_family(model_id: str) -> str:
    mid = (model_id or "").lower()

    # Anthropic Claude
    if mid.startswith("anthropic."):
        return "anthropic_claude"

    # Meta Llama
    if mid.startswith("meta."):
        return "meta_llama"

    # Amazon Nova (model IDs or inference profile IDs)
    if mid.startswith("amazon.nova") or mid.startswith("us.amazon.nova"):
        return "amazon_nova"

    return "unknown"


# Bedrock invocation helpers
def _invoke_claude(model_id: str, system: str, user: str) -> str:
    """
    Claude Messages schema for Bedrock Runtime.
    Use correct content blocks (matches your claude.py). :contentReference[oaicite:2]{index=2}
    """
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1800,
        "temperature": 0.2,
        "system": system,
        "messages": [{"role": "user", "content": [{"type": "text", "text": user}]}],
    }

    resp = bedrock.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(body).encode("utf-8"),
    )
    payload = json.loads(resp["body"].read())

    content = payload.get("content", [])
    if isinstance(content, list):
        parts = []
        for p in content:
            if isinstance(p, dict) and p.get("type") == "text" and isinstance(p.get("text"), str):
                parts.append(p["text"])
        if parts:
            return "\n".join(parts).strip()

    return json.dumps(payload, indent=2)


def _format_llama_prompt(system: str, user: str) -> str:
    if system:
        return (
            "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n"
            f"{system}<|eot_id|><|start_header_id|>user<|end_header_id|>\n"
            f"{user}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n"
        )
    return (
        "<|begin_of_text|><|start_header_id|>user<|end_header_id|>\n"
        f"{user}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\n"
    )


def _invoke_meta_llama(model_id: str, prompt: str) -> str:
    llama_prompt = _format_llama_prompt(
        system="You are an SRE incident reporter. Return ONLY Markdown following the template headings exactly.",
        user=prompt,
    )

    body = {
        "prompt": llama_prompt,
        "temperature": 0.2,
        "top_p": 0.9,
        "max_gen_len": 1800,
    }

    resp = bedrock.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(body).encode("utf-8"),
    )
    payload = json.loads(resp["body"].read())

    if isinstance(payload, dict) and isinstance(payload.get("generation"), str):
        return payload["generation"]

    return json.dumps(payload, indent=2)


def _invoke_amazon_nova(model_id: str, prompt: str) -> str:
    request_body = {
        "schemaVersion": "messages-v1",
        "system": [
            {"text": "You are an SRE incident reporter. Return ONLY Markdown following the template headings exactly."}
        ],
        "messages": [
            {"role": "user", "content": [{"text": prompt}]}
        ],
        "inferenceConfig": {
            "maxTokens": 2000,
            "temperature": 0.2,
            "topP": 0.9,
        },
    }

    resp = bedrock.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(request_body).encode("utf-8"),
    )
    payload = json.loads(resp["body"].read())

    out = payload.get("output", {}).get("message", {}).get("content", [])
    texts = []
    if isinstance(out, list):
        for block in out:
            if isinstance(block, dict) and isinstance(block.get("text"), str):
                texts.append(block["text"])

    if texts:
        return "\n".join(texts).strip()

    return json.dumps(payload, indent=2)


def invoke_model_to_text(model_id: str, system: str, user: str) -> str:
    fam = model_family(model_id)
    if fam == "anthropic_claude":
        return _invoke_claude(model_id, system=system, user=user)
    if fam == "meta_llama":
        return _invoke_meta_llama(model_id, user)
    if fam == "amazon_nova":
        return _invoke_amazon_nova(model_id, user)

    return (
        "# Incident Report (LLM Unsupported)\n\n"
        f"Model id `{model_id}` is not supported by this handler's dispatch logic.\n"
        "Add a model-family adapter in handler.py.\n"
    )

def invoke_with_fallback(system: str, user: str):
    retryable_codes = {
        "ResourceNotFoundException",
        "AccessDeniedException",
        "ValidationException",
    }

    try:
        return invoke_model_to_text(MODEL_PRIMARY, system=system, user=user), MODEL_PRIMARY
    except botocore.exceptions.ClientError as e:
        code = e.response.get("Error", {}).get("Code", "Unknown")
        msg = e.response.get("Error", {}).get("Message", str(e))

        if code not in retryable_codes:
            raise

        try:
            return invoke_model_to_text(MODEL_FALLBACK, system=system, user=user), MODEL_FALLBACK
        except botocore.exceptions.ClientError as e2:
            code2 = e2.response.get("Error", {}).get("Code", "Unknown")
            msg2 = e2.response.get("Error", {}).get("Message", str(e2))

            blocked = f"""# Incident Report (LLM Generation Blocked)

## Summary
Bedrock model invocation failed for both primary and fallback.

## Primary Model
- Model: `{MODEL_PRIMARY}`
- Error: `{code}`
- Message: {msg}

## Fallback Model
- Model: `{MODEL_FALLBACK}`
- Error: `{code2}`
- Message: {msg2}

## What still worked
- Evidence bundle was collected and written to S3.
- SNS notification fired with report/evidence locations.

## Fix
- Confirm model access is enabled in this AWS account and the same region as this Lambda.
"""
            return blocked, "none"


def INCIDENT_TEMPLATE():
    # Keep your headings unchanged to satisfy "template headings exactly" for your rubric.
    return """# Incident Report: {{incident_id}} — {{title}}

## 1. Executive Summary
- Impact:
- Customer/User Symptoms:
- Detection Method (alarm/logs):
- Severity:
- Start Time (UTC):
- End Time (UTC):
- Duration:
- Confidence (High/Medium/Low):

## 2. Timeline (UTC)
| Time | Signal                | Evidence (query/field) | Confidence |
|------|-----------------------|------------------------|------------|
|      | Alarm triggered       |                        |            |
|      | First error seen      |                        |            |
|      | Triage started        |                        |            |
|      | Root cause identified |                        |            |
|      | Fix applied           |                        |            |
|      | Service restored      |                        |            |
|      | Alarm cleared         |                        |            |

## 3. Scope and Blast Radius
- Affected components:
- Entry point (ALB / WAF):
- Downstream dependency (RDS):
- Regions/AZs:
- Confidence (High/Medium/Low):

## 4. Evidence Collected
### 4.1 CloudWatch Alarm
- Alarm name:
- Metric:
- Threshold:
- State changes:
- Confidence (High/Medium/Low):

### 4.2 App Logs (CloudWatch Logs Insights)
- Error rate over time (1m bins):
- Most recent DB-related error lines (latest 50):
- Confidence (High/Medium/Low):

### 4.3 WAF Logs (CloudWatch Logs Insights)
- Allow vs Block:
- Top blocked IP/URI pairs:
- Confidence (High/Medium/Low):

### 4.4 Configuration Sources (for Recovery)
- Parameter Store: endpoint/port/name (safe subset only)
- Secrets Manager: host/port/dbname/username only
- Notes on drift:
- Confidence (High/Medium/Low):

## 5. Root Cause Analysis
- Root cause category: (Cred drift | Network isolation | DB interruption | External attack | Other | Unknown)
- Exact failure mechanism:
- Why it wasn’t prevented:
- Contributing factors:
- Supporting Evidence: (MUST cite evidence keys for each key claim)
- Confidence (High/Medium/Low):

## 6. Resolution
- Actions taken:
- Validation checks:
- Evidence of recovery (curl + alarm OK + logs stabilized):
- Confidence (High/Medium/Low):

## 7. Recommended Next Evidence to Pull
- (Must be specific: metric, log query, config, etc.)

## 8. Preventive Actions
- Immediate (today):
- Short-term (1–2 weeks):
- Long-term (1–2 months):
- Evidence tie-back (evidence key) required.

## 9. Evidence Citations (Required)
- For each key claim, cite which evidence key supports it:
  - Claim:
    - Evidence: [evidence_key]
    - Confidence:

## 10. Redaction Statement
- Confirm no secrets (passwords/tokens) were included in this report.

## Appendix
- Logs Insights queries used:
- Report generated by: Amazon Bedrock model {{model_id}}
"""


# Required Logs Insights Query Pack (minimum)
APP_Q_ERROR_RATE_1M = r"""
fields @timestamp
| filter @message like /ERROR|Error|Exception|Traceback/
| stats count() as errors by bin(1m) as t
| sort t asc
""".strip()

APP_Q_DB_ERRORS_LATEST_50 = r"""
fields @timestamp, @message
| filter @message like /pymysql|mysql|Access denied|Can't connect|OperationalError|RDS|SQLSTATE/
| sort @timestamp desc
| limit 50
""".strip()

WAF_Q_ALLOW_VS_BLOCK = r"""
fields @timestamp, action
| stats count() as hits by action
| sort hits desc
""".strip()

WAF_Q_TOP_BLOCKED_IP_URI = r"""
fields @timestamp, action, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter action = "BLOCK"
| stats count() as hits by clientIp, uri
| sort hits desc
| limit 25
""".strip()


# Lambda entry point
def lambda_handler(event, context):
    now = int(time.time())
    start_ts = now - FAST_WINDOW_MINUTES * 60
    end_ts = now

    start_dt = datetime.datetime.fromtimestamp(start_ts, tz=datetime.timezone.utc)
    end_dt = datetime.datetime.fromtimestamp(end_ts, tz=datetime.timezone.utc)

    alarm_payload = parse_alarm_event(event)
    alarm = safe_alarm_fields(alarm_payload)

    incident_id = f"bonus_h-{iso_utc_z(end_dt).replace(':','').replace('-','')}-{uuid.uuid4().hex[:8]}"

    # Evidence collection (contract)
    ssm_params = get_ssm_params_safe(SSM_PARAM_PATH)
    secret_meta = get_secret_meta(SECRET_ID)

    # Required query pack
    q_app_error_rate = run_insights_query(APP_LOG_GROUP, APP_Q_ERROR_RATE_1M, start_ts, end_ts, limit=1000)
    q_app_db_lines = run_insights_query(APP_LOG_GROUP, APP_Q_DB_ERRORS_LATEST_50, start_ts, end_ts, limit=50)

    q_waf_allow_block = run_insights_query(WAF_LOG_GROUP, WAF_Q_ALLOW_VS_BLOCK, start_ts, end_ts, limit=1000)
    q_waf_top_blocked = run_insights_query(WAF_LOG_GROUP, WAF_Q_TOP_BLOCKED_IP_URI, start_ts, end_ts, limit=25)

    evidence = {
        "incident_id": incident_id,
        "time_window_utc": {"start": iso_utc_z(start_dt), "end": iso_utc_z(end_dt)},
        "alarm": alarm,
        "queries": {
            "app_error_rate_over_time_1m": {
                "log_group": APP_LOG_GROUP,
                "query": APP_Q_ERROR_RATE_1M,
                **q_app_error_rate,
            },
            "app_latest_50_db_related_error_lines": {
                "log_group": APP_LOG_GROUP,
                "query": APP_Q_DB_ERRORS_LATEST_50,
                **q_app_db_lines,
            },
            "waf_allow_vs_block": {
                "log_group": WAF_LOG_GROUP,
                "query": WAF_Q_ALLOW_VS_BLOCK,
                **q_waf_allow_block,
            },
            "waf_top_blocked_ip_uri_pairs": {
                "log_group": WAF_LOG_GROUP,
                "query": WAF_Q_TOP_BLOCKED_IP_URI,
                **q_waf_top_blocked,
            },
        },
        "ssm_params": {
            "endpoint": ssm_params.get("normalized", {}).get("endpoint"),
            "port": ssm_params.get("normalized", {}).get("port"),
            "name": ssm_params.get("normalized", {}).get("name"),
            "source_path": SSM_PARAM_PATH,
        },
        "secret_meta": secret_meta,
    }

    system = (
        "You are an SRE incident reporter.\n"
        "NON-NEGOTIABLE RULES:\n"
        "- Use ONLY the provided evidence JSON.\n"
        "- If unknown, write \"Unknown\".\n"
        "- Every key claim MUST cite the evidence key used (e.g., [alarm.name], [queries.waf_allow_vs_block]).\n"
        "- NEVER output secrets/passwords/tokens.\n"
        "- Output MUST be Markdown and MUST follow the template headings exactly.\n"
    )

    user = f"""
Template (use headings exactly):
{INCIDENT_TEMPLATE()}

Evidence JSON:
{json.dumps(evidence, indent=2)}

Return ONLY the final Markdown.
""".strip()

    report_md, model_used = invoke_with_fallback(system=system, user=user)

    # Store artifacts (contract paths)
    md_key = f"{REPORT_PREFIX.rstrip('/')}/{incident_id}.md"
    json_key = f"{REPORT_PREFIX.rstrip('/')}/{incident_id}.json"

    s3.put_object(
        Bucket=REPORT_BUCKET,
        Key=json_key,
        Body=json.dumps(evidence, indent=2).encode("utf-8"),
        ContentType="application/json",
    )

    s3.put_object(
        Bucket=REPORT_BUCKET,
        Key=md_key,
        Body=report_md.encode("utf-8"),
        ContentType="text/markdown",
    )

    # Notify (Report Ready)
    msg = {
        "incident_id": incident_id,
        "model_used": model_used,
        "report_s3": f"s3://{REPORT_BUCKET}/{md_key}",
        "evidence_s3": f"s3://{REPORT_BUCKET}/{json_key}",
    }

    sns.publish(
        TopicArn=SNS_TOPIC_ARN,
        Subject=f"IR Report Ready: {incident_id}",
        Message=json.dumps(msg, indent=2),
    )

    return {"ok": True, **msg}
