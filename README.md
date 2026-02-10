# 🛡️ AWS Lab 1C (Bonus E) - WAF Logging into CloudWatch Logs

![AWS](https://img.shields.io/badge/AWS-WAF%20%7C%20CloudWatch-orange?style=for-the-badge&logo=amazonaws)
![Terraform](https://img.shields.io/badge/Terraform-IaC-purple?style=for-the-badge&logo=terraform)
![Security](https://img.shields.io/badge/Security-WAF%20Logging-red?style=for-the-badge)
![CloudWatch Logs](https://img.shields.io/badge/Observability-CloudWatch%20Logs-blue?style=for-the-badge&logo=amazoncloudwatch)
![Lab Architecture](https://img.shields.io/badge/Architecture-Lab%201C%20Bonus%20E-lightgrey?style=for-the-badge)
![WAF Logs](https://img.shields.io/badge/Logs-WAF%20to%20CloudWatch%20Logs-blue?style=for-the-badge&logo=amazoncloudwatch)

---

## 📌 **Task Overview**

**Bonus E** upgrades the Lab 1C architecture to include **real-world Web Application Firewall (WAF) logging** using **Amazon CloudWatch Logs**.

This bonus transforms WAF from a “black box” into an **observable security control**, enabling fast investigation, attack attribution, and correlation with ALB and application behavior.

> In modern AWS, WAF logs can be delivered **directly** to CloudWatch Logs, S3, or Firehose.  
> This lab intentionally selects **CloudWatch Logs** for **fast search and incident response**.

---

## 🎯 **Task Objectives**

- Enable **AWS WAF v2 logging**
- Send logs to **CloudWatch Logs**
- Enforce AWS naming requirements (`aws-waf-logs-*`)
- Verify logs via AWS CLI
- Demonstrate real-world incident-response readiness

---

## 🏗️ **Project Structure**

```plaintext
lab-1c-bonus-e/
├── Screenshots/
|   ├── bonus-e-pt1.jpg
|   ├── bonus-e-pt2.jpg
|   ├── bonus-e-pt3.jpg
|   ├── terraform-apply.jpg
|   ├── terraform-destroy.jpg
|   ├── terraform-init-fmt-validate.jpg
|   └── terraform-plan.jpg
|
├── scripts/
|   ├── lab_1c_bonus_e_waf_acl_logs.csv
|   └── user_data.sh
|
├── .gitignore
├── 1-versions.tf
├── 2-providers.tf
├── 3-locals.tf
├── 4-main.tf
├── 5-variables.tf
├── 6-route53.tf
├── 7-outputs.tf
├── README.md
└── STEPS.md
```

---

## ⚙️ **CloudWatch Logs WAF ACL Demo**

<https://github.com/user-attachments/assets/29cbecba-a78b-4c8a-ad8b-72d90da1a912>

---

## 🛠️ **Terraform Deployment**

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

---

## 🔍 **Verification (Authoritative)**

### Confirm WAF Logging Configuration

```bash
aws wafv2 get-logging-configuration \
  --resource-arn arn:aws:wafv2:us-east-1:866340886126:regional/webacl/lab-1c-waf/e118dcd8-9cd4-4e2b-a5d0-5d72ecff4396
```

![bonus-e-pt1.jpg](/Screenshots/bonus-e-pt1.jpg)

**Expected Result:**

- `LogDestinationConfigs` contains **exactly one** destination

---

### Generate Traffic (Hits + Blocks)

```bash
curl -I https://theinternationalquietstorm.com/
curl -I https://app.theinternationalquietstorm.com/
```

![bonus-e-pt2.jpg](/Screenshots/bonus-e-pt2.jpg)

---

### Inspect CloudWatch Logs

```bash
aws logs describe-log-streams \
  --log-group-name aws-waf-logs-lab-1c-web-acl \
  --order-by LastEventTime --descending
```

![bonus-e-pt3.jpg](/Screenshots/bonus-e-pt3.jpg)

Pull recent events:

```bash
aws logs filter-log-events \
  --log-group-name aws-waf-logs-lab-1c-web-acl \
  --max-items 20
```

<https://github.com/user-attachments/assets/1c0f0aca-e810-4073-b2c1-ef0b4a762bd8>

---

## 🧠 **Why This Matters (Real-World Security)**

With WAF logging enabled, you can now answer:

- Are 5xx errors caused by **attack traffic or backend failure?**
- Do WAF blocks spike before ALB errors?
- Which **IPs, countries, or paths** are hammering the app?
- Is WAF successfully mitigating threats, or are they reaching origin?

This is **production-grade observability**, not checkbox security.

---

## 🧹 **Teardown**

```bash
terraform destroy
```

![terraform-destroy.jpg](/Screenshots/terraform-destroy.jpg)

---

## 📚 References

- AWS Documentation – *Logging web ACL traffic*  
  <https://docs.aws.amazon.com/waf/latest/developerguide/logging.html>

- AWS API Reference – *WAFv2 LoggingConfiguration*  
  <https://docs.aws.amazon.com/waf/latest/APIReference/API_LoggingConfiguration.html>

- Terraform Registry – *aws_wafv2_web_acl_logging_configuration*  
  <https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration>

- AWS Documentation – *Using Amazon CloudWatch Logs*  
  <https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html>

- AWS Documentation – *Viewing and analyzing log data in CloudWatch Logs*  
  <https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html>

- AWS Well-Architected Framework – *Security Pillar*  
  <https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/>

---

## 🛠️ Troubleshooting Steps

### WAF logging not appearing

- Confirm logging is enabled:

```bash
aws wafv2 get-logging-configuration --resource-arn <WEB_ACL_ARN>
```

- Ensure **exactly one** log destination is listed.
- Verify the log group name starts with:

```text
aws-waf-logs-
```

### `WAFNonexistentItemException`

- The Web ACL ARN may be incorrect.

- Ensure:
  - WAF scope is **regional**
  - Region matches the ALB (`us-east-1` for this lab)

### CloudWatch log group exists but no events

- Generate traffic:

```bash
curl -I https://theinternationalquietstorm.com/
curl -I https://app.theinternationalquietstorm.com/
```

- Wait 1–2 minutes (WAF logs are near-real-time, not instant).

- Re-run:

```bash
aws logs filter-log-events --log-group-name aws-waf-logs-<project>-web-acl
```

### Terraform apply fails with “InvalidParameter”

- Ensure the log destination name:
  - Starts with `aws-waf-logs-`
  - Is **not reused** by another Web ACL

- Verify only **one** `aws_wafv2_web_acl_logging_configuration` resource is active.

---

### AccessDenied when writing logs

- Confirm CloudWatch Logs service is available in the region.
- Verify no SCPs or permission boundaries block WAF logging.
- Ensure the log group was created **before** logging configuration:

```bash
terraform apply
```

### Logs exist but show only `ALLOW`

- This is expected if:

  - No managed rules are blocking traffic
  - Traffic does not trigger rule thresholds

- Try:

  - Sending malformed headers
  - Exceeding rate-limit rules (if configured)

### Need deeper visibility (stretch goal)

- Add `redacted_fields` to hide sensitive headers
- Add `logging_filter` to isolate BLOCK actions only
- Correlate WAF logs with:

  - ALB access logs
  - CloudWatch ALB 5xx metrics

---

## 👥 **Authors**

- **Author:** T.I.Q.S.
- **Group Leader:** John Sweeney
