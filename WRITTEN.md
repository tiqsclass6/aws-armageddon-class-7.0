# **AWS Armageddon – Lab 1C Bonus F**

## **Written Submission: CloudWatch Logs Insights Incident Response**

---

## **Overview**

Lab 1C – Bonus F builds on the observability foundation established in Bonus E by introducing a **structured incident-response workflow** using **Amazon CloudWatch Logs Insights**. While Bonus E focused on enabling and validating Web Application Firewall (WAF) logging, Bonus F focuses on **analyzing, correlating, and interpreting log data** to determine the root cause of alarms and application failures.

This bonus mirrors real-world Site Reliability Engineering (SRE) and Security Operations (SecOps) practices, where engineers must quickly determine whether an incident is caused by **external attack activity** or **internal backend failure**.

---

## **Logging Scope and Assumptions**

CloudWatch Logs Insights operates exclusively on logs that reside in **CloudWatch Logs**. As such, the analysis in this bonus applies to:

* **AWS WAF v2 logs** delivered directly to CloudWatch Logs
* **Application logs** emitted by EC2 instances and written to an `/aws/ec2/<prefix>-rds-app` log group

ALB access logs are intentionally excluded from this workflow because they are stored in **Amazon S3**, not CloudWatch Logs. In enterprise environments, ALB logs are typically analyzed using **Athena** or centralized log-lake pipelines. For this lab, ALB behavior is correlated indirectly using **CloudWatch metrics and alarms**.

---

## **WAF Log Analysis**

The first stage of the incident workflow focuses on understanding **current security behavior** at the edge.

### **Top Actions (ALLOW vs BLOCK)**

The initial WAF query aggregates request counts by action (ALLOW or BLOCK). This immediately answers whether the WAF is actively mitigating traffic or simply observing benign requests. A spike in BLOCK actions during the alarm window strongly suggests external scanning or attack traffic.

### **Client IP and URI Analysis**

Subsequent queries identify:

* The **top client IPs** generating traffic
* The **most frequently requested URIs**

These queries reveal whether traffic is evenly distributed (typical user behavior) or concentrated around suspicious paths such as administrative endpoints, login pages, or configuration files.

### **Blocked Requests and Rule Attribution**

Filtered queries isolate only BLOCK actions and attribute them to:

* Specific client IPs
* Requested URIs
* The terminating WAF rule and rule type

This allows precise determination of *which* security control triggered and *why*, which is essential during post-incident review.

### **Suspicious Scanner Detection**

Regex-based URI matching is used to detect common scanning behavior (e.g., `wp-login`, `xmlrpc`, `.env`, `admin`, `.git`). A sudden increase in these patterns is a strong indicator of automated probing rather than legitimate user traffic.

### **Geographic Distribution (Optional)**

When country metadata is present in WAF logs, geographic aggregation helps identify anomalous access patterns or unexpected regions generating high traffic volume.

---

## **Application Log Analysis**

If WAF analysis does not indicate an external attack, attention shifts to **backend application behavior**.

### **Error Rate Over Time**

Application logs are scanned for error indicators such as exceptions, database failures, timeouts, and connection refusals. Errors are grouped into one-minute bins to align precisely with CloudWatch alarm evaluation windows.

This visualization answers a critical question:

> *Did application errors spike at the same time as the alarm?*

### **Recent Database Failures**

A targeted query extracts the most recent database-related failures. This provides a fast triage view into connectivity, authentication, or availability issues without needing to SSH into instances.

### **Credentials vs Network Classification**

Error messages are classified into categories:

* **Credentials/Auth** (e.g., access denied, authentication failures)
* **Network/Route** (e.g., timeouts, no route to host)
* **Port/Security Group/Service** (e.g., connection refused)

This classification allows responders to rapidly determine whether the failure is caused by:

* Secrets drift
* Security group or routing misconfiguration
* Downstream service outages

### **Structured JSON Log Analysis (Optional)**

If application logs are emitted in structured JSON format, CloudWatch Logs Insights can extract fields such as `event` and `reason`. This enables aggregation by error type and supports more advanced analytics. This capability requires deliberate application logging design and is treated as an advanced enhancement.

---

## **Correlation and Incident Workflow**

The core value of Bonus F lies in **correlation**, not isolated log inspection.

### **Step 1 – Confirm Signal Timing**

* Review the CloudWatch alarm time window (typically 5–15 minutes)
* Compare against application error spikes

### **Step 2 – Determine Attack vs Backend Failure**

* WAF BLOCK spike aligned with alarm → likely external scanning or attack
* Quiet WAF with rising application errors → likely backend failure

### **Step 3 – Backend Triage**

* Authentication errors → investigate Secrets Manager and Parameter Store
* Timeouts or refusals → investigate security groups, routing, or RDS health

Known-good values are retrieved from:

* AWS Systems Manager Parameter Store (`/lab/db/*`)
* AWS Secrets Manager (`/<prefix>/rds/mysql`)

### **Step 4 – Verify Recovery**

* Application error rates return to baseline
* WAF block patterns stabilize
* CloudWatch alarm transitions back to `OK`
* Application responds successfully to validation requests

---

## **Why This Matters**

Bonus F reflects **real production expectations**:

* Logs are useless unless they can be **queried quickly and correctly**
* Alarms without context lead to wasted time and incorrect remediation
* Security and reliability teams must work from the **same data sources**

This bonus demonstrates the ability to:

* Design observability intentionally
* Perform disciplined incident triage
* Distinguish symptoms from root causes
* Operate cloud infrastructure with an enterprise mindset

---

## **Conclusion**

Lab 1C – Bonus F elevates the project from infrastructure deployment to **operational maturity**. By combining WAF telemetry, application logs, CloudWatch alarms, and structured analysis, this bonus delivers a realistic, enterprise-grade incident-response workflow aligned with modern AWS best practices.

---

## **Author**

* **Author:** T.I.Q.S.
* **Group Leader:** John Sweeney

---
