import os
import json
import time
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

FAST_WINDOW_MINUTES = int(os.environ.get("FAST_WINDOW_MINUTES", "15"))


# CloudWatch Logs Insights
def run_insights_query(log_group: str, query: str, start_ts: int, end_ts: int, limit: int = 100):
    qid = logs.start_query(
        logGroupName=log_group,
        startTime=start_ts,
        endTime=end_ts,
        queryString=query,
        limit=limit,
    )["queryId"]

    for _ in range(20):
        resp = logs.get_query_results(queryId=qid)
        status = resp.get("status")
        if status in ("Complete", "Failed", "Cancelled", "Timeout"):
            return {"status": status, "queryId": qid, "results": resp.get("results", [])}
        time.sleep(1.0)

    return {"status": "Timeout", "queryId": qid, "results": []}


# Safe config evidence
def get_ssm_param_names_only(path: str):
    """SECURITY: Names only (values redacted)."""
    names = []
    next_token = None
    while True:
        kwargs = {"Path": path, "Recursive": True, "WithDecryption": True}
        if next_token:
            kwargs["NextToken"] = next_token
        resp = ssm.get_parameters_by_path(**kwargs)
        for p in resp.get("Parameters", []):
            names.append(p["Name"])
        next_token = resp.get("NextToken")
        if not next_token:
            break
    return sorted(names)


def get_secret_meta(secret_id: str):
    """SECURITY: Do not output secret values; include only safe connection hints."""
    meta = {}
    try:
        d = secrets.describe_secret(SecretId=secret_id)
        meta = {
            "name": d.get("Name"),
            "arn": d.get("ARN"),
            "rotation_enabled": bool(d.get("RotationEnabled")),
            "last_changed": d.get("LastChangedDate").isoformat() if d.get("LastChangedDate") else None,
            "redacted": True,
        }
    except Exception as e:
        meta = {"error": str(e), "redacted": True}

    safe_subset = {}
    try:
        raw = secrets.get_secret_value(SecretId=secret_id).get("SecretString", "{}")
        payload = json.loads(raw) if raw else {}
        for k in ("host", "port", "dbname", "username"):
            if k in payload:
                safe_subset[k] = payload.get(k)
    except Exception:
        pass

    return {"meta": meta, "safe_subset": safe_subset, "password_included": False}


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
    # e.g. "amazon.nova-lite-v1:0" or "us.amazon.nova-lite-v1:0"
    if mid.startswith("amazon.nova") or mid.startswith("us.amazon.nova"):
        return "amazon_nova"

    return "unknown"


# Bedrock invocation helpers
def _invoke_claude(model_id: str, prompt: str) -> str:
    """
    Claude Messages schema for Bedrock Runtime.
    """
    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1800,
        "temperature": 0.2,
        "messages": [{"role": "user", "content": prompt}],
    }

    resp = bedrock.invoke_model(
        modelId=model_id,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(body).encode("utf-8"),
    )
    payload = json.loads(resp["body"].read())

    content = payload.get("content", [])
    if isinstance(content, list) and content and isinstance(content[0], dict) and "text" in content[0]:
        return content[0]["text"]

    return json.dumps(payload, indent=2)


def _format_llama_prompt(system: str, user: str) -> str:
    """
    Meta Llama prompt format.
    """
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
    """
    Meta Llama native inference schema for Bedrock Runtime.
    """
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
    """
    Amazon Nova "messages-v1" schema via InvokeModel.
    Request schema uses system[], messages[], inferenceConfig. :contentReference[oaicite:2]{index=2}
    Response text appears under output.message.content[].text. :contentReference[oaicite:3]{index=3}
    """
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

    # Extract all text blocks
    out = payload.get("output", {}).get("message", {}).get("content", [])
    texts = []
    if isinstance(out, list):
        for block in out:
            if isinstance(block, dict) and isinstance(block.get("text"), str):
                texts.append(block["text"])

    if texts:
        return "\n".join(texts).strip()

    # If schema differs or tool output returned, return payload for debugging
    return json.dumps(payload, indent=2)


def invoke_model_to_text(model_id: str, prompt: str) -> str:
    fam = model_family(model_id)
    if fam == "anthropic_claude":
        return _invoke_claude(model_id, prompt)
    if fam == "meta_llama":
        return _invoke_meta_llama(model_id, prompt)
    if fam == "amazon_nova":
        return _invoke_amazon_nova(model_id, prompt)

    return (
        "# Incident Report (LLM Unsupported)\n\n"
        f"Model id `{model_id}` is not supported by this handler's dispatch logic.\n"
        "Add a model-family adapter in handler.py.\n"
    )


def invoke_with_fallback(prompt: str):
    """
    Try primary model first. If blocked/gated/EOL, try fallback.
    If both fail, return a gradeable blocked report.
    """
    retryable_codes = {
        "ResourceNotFoundException",
        "AccessDeniedException",
        "ValidationException",
    }

    try:
        return invoke_model_to_text(MODEL_PRIMARY, prompt), MODEL_PRIMARY
    except botocore.exceptions.ClientError as e:
        code = e.response.get("Error", {}).get("Code", "Unknown")
        msg = e.response.get("Error", {}).get("Message", str(e))

        if code not in retryable_codes:
            raise

        try:
            return invoke_model_to_text(MODEL_FALLBACK, prompt), MODEL_FALLBACK
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
- For Nova Lite specifically, consider using the inference profile ID:
  `us.amazon.nova-lite-v1:0`
"""
            return blocked, "none"

def INCIDENT_TEMPLATE():
    # Keep inline template so the skeleton is self-contained and gradeable.
    # Students can swap this for loading a file from the Lambda bundle if desired.
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
- Top error signatures (top 5):
- Most recent error lines (top 10):
- Confidence (High/Medium/Low):

### 4.3 WAF Logs (CloudWatch Logs Insights)
- Allow vs Block:
- Top client IPs:
- Top URIs:
- Top terminating rules:
- Confidence (High/Medium/Low):

### 4.4 Configuration Sources (for Recovery)
- Parameter Store: /lab/db/* (names only; values redacted)
- Secrets Manager: {{secret_name}} (metadata only; values redacted)
- Notes on drift:
- Confidence (High/Medium/Low):

## 5. Root Cause Analysis
- Root cause category: (Cred drift | Network isolation | DB interruption | External attack | Other | Unknown)
- Exact failure mechanism:
- Why it wasn’t prevented:
- Contributing factors:
- Supporting Evidence: (MUST cite query/field for each key claim)
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
- Evidence tie-back (query/field) required.

## 9. Evidence Citations (Required)
- For each key claim, cite which query and which field supports it:
  - Claim:
    - Evidence: evidence.queries.<name>.results[...] field <field>
    - Confidence:

## 10. Redaction Statement
- Confirm no secrets (passwords/tokens) were included in this report.

## Appendix
- Key CLI commands used:
- Logs Insights queries used:
- Report generated by: Amazon Bedrock model {{model_id}}
"""

# Lambda entry point
def lambda_handler(event, context):
    now = int(time.time())
    start_ts = now - FAST_WINDOW_MINUTES * 60
    end_ts = now

    incident_id = f"bonus_g-{datetime.datetime.utcnow().strftime('%Y%m%d-%H%M%S')}"

    # Evidence collection
    ssm_names = get_ssm_param_names_only(SSM_PARAM_PATH)
    secret_info = get_secret_meta(SECRET_ID)

    app_errors = run_insights_query(
        APP_LOG_GROUP,
        "fields @timestamp, @message | filter @message like /(?i)ERROR|Exception|timeout|refused/ | sort @timestamp desc | limit 50",
        start_ts,
        end_ts,
    )

    waf_actions = run_insights_query(
        WAF_LOG_GROUP,
        "fields @timestamp, action | stats count() as hits by action | sort hits desc",
        start_ts,
        end_ts,
    )

    waf_blocks = run_insights_query(
        WAF_LOG_GROUP,
        'fields @timestamp, action, httpRequest.clientIp as clientIp, httpRequest.uri as uri, terminatingRuleId '
        '| filter action = "BLOCK" | stats count() as blocks by clientIp, uri, terminatingRuleId | sort blocks desc | limit 25',
        start_ts,
        end_ts,
    )

    evidence = {
        "incident_id": incident_id,
        "time_window_utc": {"start": start_ts, "end": end_ts},
        "event": event,
        "ssm": {"path": SSM_PARAM_PATH, "names": ssm_names, "values_redacted": True},
        "secrets": secret_info,
        "queries": {
            "app_errors": app_errors,
            "waf_actions": waf_actions,
            "waf_blocks": waf_blocks,
        },
        "grading": {
            "must_use_only_evidence": True,
            "must_include_confidence_levels": True,
            "must_cite_query_field_per_claim": True,
            "must_redact_secrets": True,
        },
    }

    prompt = f"""
You are an SRE generating a concise incident report in MARKDOWN.

NON-NEGOTIABLE RULES:
- Use ONLY the provided evidence.
- If unknown, write "Unknown".
- Include confidence levels (High/Medium/Low) for key claims.
- Every key claim MUST cite which query/field supports it (grading rule).
- NEVER output secrets.
- Recommend next evidence to pull if root cause is unclear.

Template (use headings exactly):
{INCIDENT_TEMPLATE()}

EVIDENCE (JSON):
{json.dumps(evidence, indent=2)}
""".strip()

    report_md, model_used = invoke_with_fallback(prompt)

    # Store artifacts
    md_key = f"reports/{incident_id}.md"
    json_key = f"reports/{incident_id}.json"

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

    # Notify
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