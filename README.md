# 🤖 Lab 1C — Bonus H (MTTR Automation with Bedrock)

![AWS](https://img.shields.io/badge/AWS-Cloud%20Native-orange?logo=amazonaws)
![Terraform](https://img.shields.io/badge/Terraform-IaC-blueviolet?logo=terraform)
![Lambda](https://img.shields.io/badge/Lambda-Serverless-success?logo=awslambda)
![Bedrock](https://img.shields.io/badge/Amazon%20Bedrock-LLM-purple)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)

---

## 📌 Task Overview

This lab implements **automated incident response reporting** using **AWS Lambda**, **CloudWatch Logs Insights**, **Amazon Bedrock**, and **SNS**.

When a CloudWatch alarm fires, the system automatically:

1. Collects structured evidence (logs, configuration, metadata)
2. Generates a **human-readable incident report** using Amazon Bedrock
3. Stores both the **evidence bundle (JSON)** and **incident report (Markdown)** in S3
4. Notifies on-call engineers via SNS

This mirrors **real enterprise Mean-Time-to-Recovery (MTTR) reduction workflows** used by SRE and platform teams.

---

## 🎯 Why This Matters

- **Reduced MTTR**: No manual log digging during incidents
- **Consistent Postmortems**: Structured, repeatable reports
- **Context-Rich Alerts**: Engineers receive evidence, not just alarms
- **LLM Guardrails**: “Use only evidence / If unknown say Unknown / Cite sources”

---

## 🧩 Task Requirements

### Functional

- SNS → Lambda alarm ingestion (supports fake alarm harness)
- CloudWatch Logs Insights queries (App + WAF)
- Automated evidence collection:
  - Logs
  - SSM Parameters (safe subset)
  - Secrets metadata (no passwords)
- Amazon Bedrock report generation
- S3 storage of artifacts
- SNS notification when report is ready

### Security

- No secrets or passwords in evidence bundle
- S3 bucket private + encrypted
- IAM least-privilege policies

---

## 🗂️ Project Structure

```text
lab-1c-bonus-h/
├── deliverables/
│   ├── bonus_h-20260209T165559Z-b59a54a9.json
│   ├── bonus_h-20260209T165559Z-b59a54a9.md
│   ├── bonus_h-20260209T170158Z-68f754ac.json
│   ├── bonus_h-20260209T170158Z-68f754ac.md
│   ├── lambda-test-bonus-h.json
│   └── lambda-test-bonus-h.md
|
├── lambda/
│   └── incident_reporter/
│       ├── bonus_g_bedrock_template.md
│       ├── build.sh
│       ├── claude.py
│       ├── handler.py
│       └── incident_reporter.zip
|
├── Screenshots/
│   ├── bonus-h-pt1.jpg
│   ├── bonus-h-pt2.jpg
│   ├── bonus-h-pt3.jpg
│   ├── lambda-test-cloudwatch-alarm.jpg
│   ├── terraform-apply.jpg
│   ├── terraform-destroy.jpg
│   ├── terraform-init-fmt-validate.jpg
│   └── terraform-plan.jpg
|
├── scripts/
│   └── user_data.sh
│
├── .gitignore
├── 1-versions.tf
├── 2-providers.tf
├── 3-locals.tf
├── 4-main.tf
├── 5-variables.tf
├── 6-route53.tf
├── 7-cw-insight-queries.tf
├── 8-bedrock.tf
├── 9-outputs.tf
├── README.md
└── STEPS.md
```

---

## 🚀 Terraform Deployment Steps

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

![terraform-init-fmt-validate.jpg](/Screenshots/terraform-init-fmt-validate.jpg)
![terraform-plan.jpg](/Screenshots/terraform-plan.jpg)
![terraform-apply.jpg](/Screenshots/terraform-apply.jpg)

> Lambda packaging is handled **locally** via `build.sh` (class-safe approach).

---

## 🧪 Validation & CLI Evidence (from [STEPS.md](STEPS.md))

### Confirm Lambda Configuration

```bash
aws lambda get-function \
  --function-name lab-1c-bonus-h-incident-reporter \
  --query 'Configuration.[FunctionName,Runtime,Timeout,MemorySize]' \
  --output table
```

### Confirm SNS Subscription

```bash
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:866340886126:lab-1c-db-incidents \
  --query 'Subscriptions[].Endpoint'
```

![bonus-h-pt1.jpg](/Screenshots/bonus-h-pt1.jpg)

### Trigger Incident (Fake Alarm) in Lambda Test Harness

> Run this payload in the Lambda Console test event (SNS-wrapped format):

```json
{
  "Records": [
    {
      "Sns": {
        "Subject": "ALARM: lab-1c-db-connection-failure",
        "Message": "{\"AlarmName\":\"lab-1c-db-connection-failure\",\"NewStateValue\":\"ALARM\",\"NewStateReason\":\"Threshold crossed\",\"StateChangeTime\":\"2025-12-27T16:00:00Z\"}"
      }
    }
  ]
}
```

![lambda-test-cloudwatch-alarm.jpg](/Screenshots/lambda-test-cloudwatch-alarm.jpg)

### Confirm Reports in S3

```bash
aws s3 ls s3://lab-1c-bonus-h-ir-866340886126/reports/ --recursive | tail
```

![bonus-h-pt2.jpg](/Screenshots/bonus-h-pt2.jpg)

### Download Incident Report (Markdown)

```bash
aws s3 cp \
  s3://lab-1c-bonus-h-ir-866340886126/reports/bonus_h-20260209T171922Z-97e21858.md \
  lambda-test-bonus-h.md
```

### Validate NO Secrets Leaked (Critical)

```bash
aws s3 cp \
  s3://lab-1c-bonus-h-ir-866340886126/reports/bonus_h-20260209T171922Z-97e21858.json \
  - | grep -i password && echo FAIL
```

### Download Evidence Bundle (JSON)

```bash
aws s3 cp \
  s3://lab-1c-bonus-h-ir-866340886126/reports/bonus_h-20260209T171922Z-97e21858.json \
  lambda-test-bonus-h.json
```

![bonus-h-pt3.jpg](/Screenshots/bonus-h-pt3.jpg)

---

## 📦 Deliverables

- [**Lambda Test Report (Markdown)**](/deliverables/lambda-test-bonus-h.md)
- [**Lambda Test Evidence Bundle (JSON)**](/deliverables/bonus_h-20260209T170158Z-68f754ac.json)

---

## 🧹 Teardown Instructions

```bash
terraform destroy
```

![terraform-destroy.jpg](/Screenshots/terraform-destroy.jpg)

> (Optional) Unsubscribe Lambda from SNS first if preserving resources for review.

---

## 📚 References

- Amazon Bedrock InvokeModel
  [https://docs.aws.amazon.com/bedrock/latest/userguide/inference-invoke.html](https://docs.aws.amazon.com/bedrock/latest/userguide/inference-invoke.html)
- CloudWatch Logs Insights
  [https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)
- AWS Lambda + SNS
  [https://docs.aws.amazon.com/lambda/latest/dg/with-sns.html](https://docs.aws.amazon.com/lambda/latest/dg/with-sns.html)

---

## 🛠️ Troubleshooting

| Issue                        | Resolution                             |
| ---------------------------- | -------------------------------------- |
| Logs Insights MalformedQuery | Use aliases when sorting `bin()`       |
| Bedrock access denied        | Enable model access in region          |
| Empty report                 | Verify log groups contain recent data  |
| Secrets leaked               | Fix secret filtering logic immediately |

---

## 👤 Author

- **Author:** T.I.Q.S.
- **Group Leader:** John Sweeney

---
