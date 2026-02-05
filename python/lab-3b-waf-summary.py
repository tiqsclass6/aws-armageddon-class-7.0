#!/usr/bin/env python3
import boto3
import json
from datetime import datetime, UTC

"""
Reason why Darth Malgus would be pleased with this script:
Malgus demands proof of control. A WAF that silently allows threats is no weapon at all.
This script counts Allow vs Block decisions — visible enforcement, not promises.

Reason why this script is relevant to your career:
In regulated environments, proving that security controls are actively rejecting invalid traffic
is table stakes for compliance audits (APPI, HIPAA, PCI-DSS, SOC 2). Manual log review doesn't scale.

How you would talk about this script at an interview:
"I created a lightweight WAF log summarizer that queries recent CloudWatch Logs or S3-delivered
WAF logs, aggregates Allow/Block counts, and exports structured JSON for audit evidence bundles."
"""

def get_waf_summary(log_group_name: str, region: str = "sa-east-1", hours_back: int = 24):
    logs_client = boto3.client("logs", region_name=region)

    try:
        logs_client.describe_log_groups(logGroupNamePrefix=log_group_name)
    except logs_client.exceptions.ResourceNotFoundException:
        return None
    except Exception as e:
        raise RuntimeError(f"Failed to check log group existence: {str(e)}")

    query = """
    fields @timestamp, action
    | filter action in ["ALLOW", "BLOCK"]
    | stats count(*) as count by action
    | sort count desc
    """

    start_time = int((datetime.now(UTC).timestamp() - hours_back * 3600) * 1000)
    end_time   = int(datetime.now(UTC).timestamp() * 1000)

    try:
        response = logs_client.start_query(
            logGroupName=log_group_name,
            startTime=start_time,
            endTime=end_time,
            queryString=query
        )
        query_id = response["queryId"]
    except logs_client.exceptions.ResourceNotFoundException:
        return None
    except Exception as e:
        raise RuntimeError(f"Failed to start query: {str(e)}")

    while True:
        result = logs_client.get_query_results(queryId=query_id)
        status = result["status"]
        if status in ["Complete", "Failed", "Cancelled"]:
            break
        import time
        time.sleep(1.5)

    if status != "Complete":
        raise RuntimeError(f"Query did not complete successfully: {status}")

    summary = {"ALLOW": 0, "BLOCK": 0, "query_time_range_hours": hours_back}

    results = result.get("results", [])
    if not results:
        return summary

    for row in results:
        action = None
        count = 0
        for field in row:
            if field["field"] == "action":
                action = field["value"]
            if field["field"] == "count":
                count = int(field["value"])
        if action in summary:
            summary[action] = count

    summary["total_decisions"] = summary["ALLOW"] + summary["BLOCK"]
    summary["block_rate_percent"] = round(
        (summary["BLOCK"] / summary["total_decisions"] * 100)
        if summary["total_decisions"] > 0 else 0, 1
    )

    return summary


def main():
    log_group_name = "/aws/waf/lab-3b"
    region         = "sa-east-1"
    lookback_hours = 24

    try:
        summary = get_waf_summary(log_group_name, region, lookback_hours)

        if summary is None:
            output = {
                "status": "no_waf_logging_configured",
                "message": (
                    "No WAF logging is currently configured or no matching log group was found. "
                    "This script requires AWS WAF logging to be enabled to a CloudWatch Logs group. "
                    "For Lab 3B, this deliverable can be skipped or noted as not implemented, "
                    "as WAF proof is desirable but not strictly mandatory."
                ),
                "metadata": {
                    "attempted_log_group": log_group_name,
                    "region": region,
                    "lookback_hours": lookback_hours,
                    "generated_at": datetime.now(UTC).isoformat() + "Z"
                }
            }
        else:
            output = {
                "waf_summary": summary,
                "metadata": {
                    "generated_at": datetime.now(UTC).isoformat() + "Z",
                    "region": region,
                    "log_group": log_group_name,
                    "lookback_hours": lookback_hours
                }
            }

        print(json.dumps(output, indent=2))

    except Exception as e:
        print(json.dumps({
            "status": "error",
            "message": str(e),
            "note": "Unexpected error. Verify AWS credentials, region, and IAM permissions for CloudWatch Logs."
        }, indent=2))


if __name__ == "__main__":
    main()