#!/usr/bin/env python3
import boto3
import json
from datetime import datetime, timedelta, timezone

"""
Reason why Darth Malgus would be pleased with this script:
Change without proof is betrayal. Malgus records every saber swing.
This script surfaces the last configuration changes — immutable evidence of who touched what.

Reason why this script is relevant to your career:
Audit trails are mandatory in regulated environments. Being able to quickly show "who last modified
the security group / TGW route / WAF ACL / CloudFront config" is a frequent auditor / incident response ask.

How you would talk about this script at an interview:
"I built a CloudTrail event extractor focused on high-risk management actions (security groups, TGW,
WAF, CloudFront). It filters recent events across regions and outputs structured JSON for audit bundles."
"""

def get_recent_changes(region: str, lookback_hours: int = 72, max_results: int = 20):
    client = boto3.client("cloudtrail", region_name=region)
    
    events = []
    paginator = client.get_paginator("lookup_events")
    
    for page in paginator.paginate(
        LookupAttributes=[{"AttributeKey": "ReadOnly", "AttributeValue": "false"}],
        StartTime=datetime.now(timezone.utc) - timedelta(hours=lookback_hours),
        EndTime=datetime.now(timezone.utc),
        PaginationConfig={"MaxItems": max_results}
    ):
        for event in page.get("Events", []):
            if any(k in event["EventName"] for k in [
                "Modify", "Update", "Create", "Delete", "Authorize", "Revoke",
                "Put", "Associate", "Disassociate", "Enable", "Disable"
            ]):
                events.append({
                    "eventTime": event["EventTime"].isoformat(),
                    "eventName": event["EventName"],
                    "username": event.get("Username", "N/A"),
                    "eventSource": event["EventSource"],
                    "awsRegion": event["AwsRegion"],
                    "eventID": event["EventID"],
                    "resources": [r["ResourceName"] for r in event.get("Resources", []) if r.get("ResourceName")]
                })
    
    return sorted(events, key=lambda x: x["eventTime"], reverse=True)


def main():
    regions = ["ap-northeast-1", "sa-east-1"]
    lookback_hours = 72
    max_results_per_region = 30
    
    output = {
        "changes": {},
        "metadata": {
            "generated_at": datetime.now(timezone.utc).isoformat() + "Z",
            "lookback_hours": lookback_hours,
            "max_results_per_region": max_results_per_region
        }
    }
    
    for region in regions:
        try:
            changes = get_recent_changes(region, lookback_hours, max_results_per_region)
            output["changes"][region] = changes
        except Exception as e:
            output["changes"][region] = {"error": str(e)}
    
    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()