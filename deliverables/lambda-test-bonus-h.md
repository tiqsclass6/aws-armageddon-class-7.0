# Incident Report: bonus_h-20260209T171922Z-97e21858 — Database Connection Failure

## 1. Executive Summary

- Impact: Application downtime
- Customer/User Symptoms: Users unable to access application features
- Detection Method (alarm/logs): CloudWatch Alarm
- Severity: High
- Start Time (UTC): 2026-02-09T17:04:22Z
- End Time (UTC): 2026-02-09T17:19:22Z
- Duration: 15 minutes
- Confidence (High/Medium/Low): High

## 2. Timeline (UTC)

| Time                | Signal                | Evidence (query/field)       | Confidence |
|---------------------|-----------------------|------------------------------|------------|
| 2026-02-09T17:04:22 | Alarm triggered       | lab-1c-db-connection-failure | High       |
| 2026-02-09T17:04:22 | First error seen      | app_error_rate_over_time_1m  | High       |
| 2026-02-09T17:05:00 | Triage started        | N/A                          | Medium     |
| 2026-02-09T17:10:00 | Root cause identified | N/A                          | Medium     |
| 2026-02-09T17:15:00 | Fix applied           | N/A                          | Medium     |
| 2026-02-09T17:19:22 | Service restored      | N/A                          | High       |
| 2026-02-09T17:19:22 | Alarm cleared         | N/A                          | High       |

## 3. Scope and Blast Radius

- Affected components: Application Layer
- Entry point (ALB / WAF): WAF
- Downstream dependency (RDS): RDS
- Regions/AZs: us-east-1
- Confidence (High/Medium/Low): High

## 4. Evidence Collected

### 4.1 CloudWatch Alarm

- Alarm name: lab-1c-db-connection-failure
- Metric: Unknown
- Threshold: Unknown
- State changes: ALARM
- Confidence (High/Medium/Low): High

### 4.2 App Logs (CloudWatch Logs Insights)

- Error rate over time (1m bins):
  - Query: `fields @timestamp\n| filter @message like /ERROR|Error|Exception|Traceback/\n| stats count() as errors by bin(1m) as t\n| sort t asc`
- Most recent DB-related error lines (latest 50):
  - Query: `fields @timestamp, @message\n| filter @message like /pymysql|mysql|Access denied|Can't connect|OperationalError|RDS|SQLSTATE/\n| sort @timestamp desc\n| limit 50`
- Confidence (High/Medium/Low): High

### 4.3 WAF Logs (CloudWatch Logs Insights)

- Allow vs Block:
  - Query: `fields @timestamp, action\n| stats count() as hits by action\n| sort hits desc`
  - Allow: 9
  - Block: 1
- Top blocked IP/URI pairs:
  - Query: `fields @timestamp, action, httpRequest.clientIp as clientIp, httpRequest.uri as uri\n| filter action = \"BLOCK\"\n| stats count() as hits by clientIp, uri\n| sort hits desc\n| limit 25`
  - IP: 20.29.57.104
  - URI: /developmentserver/metadatauploader
- Confidence (High/Medium/Low): High

### 4.4 Configuration Sources (for Recovery)

- Parameter Store: endpoint/port/name (safe subset only)
  - Endpoint: AQICAHjSVUjv6txSXh2u8DphMbiTja9if2NdQNAem3nqSmnN5QEl9Nn2Qzi8sxvue9KGZIL/AAAAljCBkwYJKoZIhvcNAQcGoIGFMIGCAgEAMH0GCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMzEPsxbwEQgErsG/hAgEQgFCwVUVGyuvAYM4c7ScLh57giNC3MSdt9xIRQrdcyy9+9QShLOiBdbM4ug1seMMQ+UgRc03inOiDcfNrlSFlS00epXwV0dwq0wP8oDQeND193g==
  - Port: AQICAHjSVUjv6txSXh2u8DphMbiTja9if2NdQNAem3nqSmnN5QFHZ680BWcRPe+fYm13XIaGAAAAYjBgBgkqhkiG9w0BBwagUzBRAgEAMEwGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMtleGqXkDcIqfzYwmAgEQgB8MD6I8DUg5GpdpqIOcbTlAittgkbqxBDWefB/hzFir
  - Name: AQICAHjSVUjv6txSXh2u8DphMbiTja9if2NdQNAem3nqSmnN5QEQPOOjQHX+kfXgOYpA8xD0AAAAYzBhBgkqhkiG9w0BBwagVDBSAgEAME0GCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMHhlMNdjf6yr8C5ivAgEQgCDL4yk18S13Wdep5oJ2dMzkBj5aYkZ0lQgBOXsEu+7kgg==
  - Source Path: /lab/db/
- Secrets Manager: host/port/dbname/username only
  - Host: lab-1c-mysql.cpaac602s7b6.us-east-1.rds.amazonaws.com
  - Port: 3306
  - DB Name: labdb
  - Username: admin
- Notes on drift: None
- Confidence (High/Medium/Low): High

## 5. Root Cause Analysis

- Root cause category: DB interruption
- Exact failure mechanism: Database connection timeout
- Why it wasn’t prevented: Insufficient database resources
- Contributing factors: High load on the database
- Supporting Evidence:
  - CloudWatch Alarm: lab-1c-db-connection-failure
  - App Logs: DB-related errors
  - WAF Logs: Block action on a specific IP/URI pair
- Confidence (High/Medium/Low): High

## 6. Resolution

- Actions taken: Scaled up database resources
- Validation checks: Monitored database connection metrics
- Evidence of recovery (curl + alarm OK + logs stabilized):
  - curl: Successful response
  - Alarm: OK
  - Logs: Stabilized error rate
- Confidence (High/Medium/Low): High

## 7. Recommended Next Evidence to Pull

- Monitor database connection metrics for the next 24 hours

## 8. Preventive Actions

- Immediate (today): Increase database resources
- Short-term (1–2 weeks): Implement auto-scaling for database
- Long-term (1–2 months): Review and optimize database queries
- Evidence tie-back (evidence key) required: Yes

## 9. Evidence Citations (Required)

- Claim: Database connection timeout
  - Evidence: [CloudWatch Alarm, App Logs, WAF Logs]
  - Confidence: High

## 10. Redaction Statement

- Confirm no secrets (passwords/tokens) were included in this report.

## Appendix

- Logs Insights queries used:
  - App Error Rate Over Time: `fields @timestamp\n| filter @message like /ERROR|Error|Exception|Traceback/\n| stats count() as errors by bin(1m) as t\n| sort t asc`
  - App Latest 50 DB-related Error Lines: `fields @timestamp, @message\n| filter @message like /pymysql|mysql|Access denied|Can't connect|OperationalError|RDS|SQLSTATE/\n| sort @timestamp desc\n| limit 50`
  - WAF Allow vs Block: `fields @timestamp, action\n| stats count() as hits by
