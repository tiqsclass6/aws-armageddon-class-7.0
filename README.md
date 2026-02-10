# 🛡️ AWS Lab 1C (Bonus F) - CloudWatch Logs Insights Incident Response

![AWS](https://img.shields.io/badge/AWS-WAF%20%7C%20CloudWatch-orange?style=for-the-badge\&logo=amazonaws)
![Terraform](https://img.shields.io/badge/Terraform-IaC-purple?style=for-the-badge\&logo=terraform)
![Security](https://img.shields.io/badge/Security-Incident%20Response-red?style=for-the-badge)
![Observability](https://img.shields.io/badge/Observability-Logs%20Insights-blue?style=for-the-badge\&logo=amazoncloudwatch)
![Lab](https://img.shields.io/badge/Lab-1C%20Bonus%20F-lightgrey?style=for-the-badge)

---

## 📌 **Task Overview**

**Bonus F** extends Bonus F by turning raw **WAF and application logs** into a **production-grade incident response workflow** using **CloudWatch Logs Insights**.

This bonus focuses on **triage, correlation, and root-cause analysis** — answering *why* alarms fired, not just *that* they fired.

---

## 🎯 **Task Objectives**

* Analyze **WAF logs** using CloudWatch Logs Insights
* Investigate **application failures** from EC2 log groups
* Correlate **security events vs backend failures**
* Validate **alarm recovery**
* Demonstrate **enterprise incident-response readiness**

---

## 📂 **Project Structure**

```plaintext
lab-1c-bonus-f/
├── Screenshots/
│   ├── cw-alarm-state-and-curl.jpg
│   ├── cw-alarm-state.jpg
│   ├── cw-log-insights-query-a1.jpg
│   ├── cw-log-insights-query-a6.jpg
│   ├── cw-log-insights-query-b1.jpg
│   ├── cw-log-insights-query-b2.jpg
│   ├── secrets-manager.jpg
│   ├── ssm-parameter.jpg
│   ├── terraform-apply.jpg
│   ├── terraform-init-fmt-validate.jpg
│   └── terraform-plan.jpg
│
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
├── 7-cw-logs-insight-queries.tf
├── 8-outputs.tf
├── README.md
└── STEPS.md
```

---

## 🏗️ **Terraform Deployment**

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

![terraform-init-fmt-validate.jpg](Screenshots/terraform-init-fmt-validate.jpg)
![terraform-plan.jpg](Screenshots/terraform-plan.jpg)
![terraform-apply.jpg](Screenshots/terraform-apply.jpg)

---

## 🔎 **WAF Queries (CloudWatch Logs Insights)**

### **A1 – What’s happening right now? (ALLOW vs BLOCK)**

```sql
fields @timestamp, action
| stats count() as hits by action
| sort hits desc
```

---

### **A2 – Top client IPs**

```sql
fields @timestamp, httpRequest.clientIp as clientIp
| stats count() as hits by clientIp
| sort hits desc
| limit 25
```

---

### **A3 – Top requested URIs**

```sql
fields @timestamp, httpRequest.uri as uri
| stats count() as hits by uri
| sort hits desc
| limit 25
```

---

### **A4 – Blocked requests only**

```sql
fields @timestamp, action, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter action = "BLOCK"
| stats count() as blocks by clientIp, uri
| sort blocks desc
| limit 25
```

---

### **A5 – Which WAF rule is blocking traffic?**

```sql
fields @timestamp, action, terminatingRuleId, terminatingRuleType
| filter action = "BLOCK"
| stats count() as blocks by terminatingRuleId, terminatingRuleType
| sort blocks desc
| limit 25
```

---

### **A6 – Suspicious scanning patterns**

```sql
fields @timestamp, httpRequest.clientIp as clientIp, httpRequest.uri as uri
| filter uri =~ /wp-login|xmlrpc|\.env|admin|phpmyadmin|\.git|login/
| stats count() as hits by clientIp, uri
| sort hits desc
| limit 50
```

---

### **A8 – Country / Geo (if present)**

```sql
fields @timestamp, httpRequest.country as country
| stats count() as hits by country
| sort hits desc
| limit 25
```

---

## 🧪 **App Queries (EC2 Log Group)**

### **B1 – Error rate over time**

```sql
fields @timestamp, @message
| filter @message like /(?i)\b(ERROR|Exception|Traceback|timeout|refused)\b/
| stats count() as error_count by bin(1m)
| sort @timestamp asc
```

---

### **B2 – Recent DB failures**

```sql
fields @timestamp, @message
| filter @message like /(?i)DB|mysql|timeout|refused|Access denied|could not connect/
| sort @timestamp desc
| limit 50
```

---

## 📸 **Screenshots**

### *(Queries executed and verified in CloudWatch Logs Insights)*

---

## 🧠 **Correlation Runbook (Enterprise-Style)**

### **Step 1 — Confirm timing**

* Check CloudWatch alarm window (last 5–15 minutes)
* Run **B1** to confirm error spike
  * ![`cw-log-insights-query-b1.jpg`](/Screenshots/cw-log-insights-query-b1.jpg)

### **Step 2 — Attack vs backend**

* Run **A1 + A6**

  * BLOCK spike → external scanning
  * Quiet WAF + app errors → backend failure
  ![`cw-log-insights-query-a1.jpg`](/Screenshots/cw-log-insights-query-a1.jpg)
  ![`cw-log-insights-query-a6.jpg`](/Screenshots/cw-log-insights-query-a6.jpg)

### **Step 3 — Backend triage**

* Run **B2**

  * Access denied → credentials drift
  * Timeout/refused → SG, routing, RDS
  ![`cw-log-insights-query-b2.jpg`](/Screenshots/cw-log-insights-query-b2.jpg)

Retrieve known-good values:

* Parameter Store: `/lab/db/*`
* Secrets Manager: `/lab/rds/mysql_v13`
  ![`secrets-manager.jpg`](/Screenshots/secrets-manager.jpg)
  ![`ssm-parameter.jpg`](/Screenshots/ssm-parameter.jpg)

### **Step 4 — Verify recovery**

* Errors return to baseline
* WAF blocks stabilize
* Alarm returns to `OK`
* `curl https://app.theinternationalquietstorm.com/list`
![`cw-alarm-state-and-curl.jpg`](/Screenshots/cw-alarm-state-and-curl.jpg)

---

## 🧹 **Teardown**

```bash
terraform destroy
```

![terraform-destroy.jpg](Screenshots/terraform-destroy.jpg)

---

## 📄 **References**

* [AWS WAF Logs Insights Queries](https://docs.aws.amazon.com/waf/latest/developerguide/waf-logs-insights-queries.html)
* [CloudWatch Logs Insights Query Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)
* [AWS Incident Response Runbooks (Sample)](https://github.com/aws-samples/aws-customer-playbook-framework)
* [AWS Security Incident Response (Template)](https://github.com/aws-samples/aws-incident-response-playbooks/blob/master/playbooks/IRP-DoS.md)
* [AWS WAF Terraform Resources](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafregional_web_acl)

---

## 🔎 Troubleshooting Tips

* **No logs in Insights?**
  * Check WAF logging configuration and permissions

* **Alarms not firing?**
  * Verify CloudWatch metric filters and thresholds

* **App logs missing?**
  * Ensure EC2 instances have correct IAM role and CloudWatch agent installed

* **Unexpected query results?**
  * Adjust time range and filters in Logs Insights query

* **Terraform errors?**
  * Review error messages, check AWS permissions, and validate configuration files

---

## 👥 **Authors**

* **Author:** T.I.Q.S.
* **Group Leader:** John Sweeney

---
