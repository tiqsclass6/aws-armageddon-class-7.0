# Lab 3B – Steps to Generate/Submit Deliverables

This document outlines the exact steps to produce the required audit evidence pack and narrative.

## Folder Structure (Deliverable A)

All evidence files must be placed inside a single folder named `audit-pack/`.

```plaintext
audit-pack/
├── 00-architecture-summary.md              # Manual summary of architecture
├── 01-data-residency-proof.txt             # RDS residency proof
├── 02-edge-proof-cloudfront.txt            # CloudFront cache behavior report
├── 03-waf-proof.txt                        # WAF Allow/Block summary (or skip note)
├── 04-cloudtrail-change-proof.txt          # Recent configuration changes
├── 05-network-corridor-proof.txt           # TGW attachments & routes
├── auditor-narrative.txt                   # Auditor narrative
└── evidence.json                           # Consolidated JSON output

```

---

## Step 1 - CLI Proof of Manual Checks

Run these commands from the project root directory.

```bash
# 1. Data residency proof – RDS only in Shinjuku
aws rds describe-db-instances --region ap-northeast-1 \
         --query "DBInstances[].{DB:DBInstanceIdentifier,AZ:AvailabilityZone,Region:'ap-northeast-1',Endpoint:Endpoint.Address}"

# No RDS instances in São Paulo
aws rds describe-db-instances --region sa-east-1 \
         --query "DBInstances[].DBInstanceIdentifier"
```

![lab-3b-pt1.jpg](/Screenshots/lab-3b-pt1.jpg)

```bash
# 2. Edge proof (CloudFront logs show cache + access)
curl -I -k https://<cloudfront_domain>
```

![lab-3b-pt2a.jpg](/Screenshots/lab-3b-pt2a.jpg)
![lab-3b-pt2b.jpg](/Screenshots/lab-3b-pt2b.jpg)

```bash
# 3. Students can prove S3 buckets/logs exist for CloudFront logs
aws s3 ls s3://lab-3b-cloudfront-logs

# If logs are under a folder/prefix:
aws s3 ls s3://lab-3b-cloudfront-logs/ --recursive | tail -n 20

# Down one log file for inspection
aws s3 cp s3://lab-3b-cloudfront-logs/lab-3b/<filename.gz> cloudfront.log.gz
```

![lab-3b-pt3.jpg](/Screenshots/lab-3b-pt3.jpg)

---

## Step 2 – Generate the Automated Evidence Files

Run these commands from the project root directory (where the `python/` folder is located).

```bash
# 1. Data residency proof – RDS only in Shinjuku
python python/lab-3b-residency-proof.py > audit-pack/01-data-residency-proof.txt

# 2. Network corridor proof – TGW attachments and routes
python python/lab-3b-tgw-corridor-proof.py > audit-pack/05-network-corridor-proof.txt

# 3. CloudTrail recent changes proof
python python/lab-3b-cloudtrail_last-changes.py > audit-pack/04-cloudtrail-change-proof.txt

# 4. WAF summary (will show "no_waf_logging_configured" if not set up)
python python/lab-3b-waf-summary.py > audit-pack/03-waf-proof.txt

# 5. Edge proof – CloudFront cache behavior (Hit/Miss/RefreshHit)
python python/lab-3b-cloudfront-log-explainer.py > audit-pack/02-edge-proof-cloudfront.txt
```

![lab-3b-pt4.jpg](/Screenshots/lab-3b-pt4.jpg)

---

## Step 3 - CloudFront Standard Log Reference Hit / Miss / RefreshHit semantics

```bash
# A. Standard logs in S3 bucket (downloaded locally for analysis)
python python/lab-3b-cloudfront-log-explainer.py \
  --bucket lab-3b-cloudfront-logs \
  --prefix lab-3b/ \
  --latest 5 \
  | tee cloudfront-part1.log cloudfront-part2.log > /dev/null

# B. Real-time logs as JSON lines
python python/lab-3b-cloudfront-log-explainer.py > realtime-logs.jsonl
```

![lab-3b-pt5.jpg](/Screenshots/lab-3b-pt5.jpg)

### Final Lab Assumptions (Locked for Grading)

- S3 Bucket: `lab-3b-cloudfront-logs` (with logs under prefix `lab-3b/`)
- CloudFront Log Prefix: `lab-3b/`
- AWS Account: Your own account where the lab is deployed

```bash
# C. Running Scripts:
python python/lab-3b-cloudfront-log-explainer.py --latest 5
python python/lab-3b-cloudfront-log-explainer.py --prefix lab-3b/ --latest 10
python python/lab-3b-cloudfront-log-explainer.py --prefix lab-3b/ --latest 5 --keep

# D. From stdin (piped input):
zcat cloudfront.log.gz | python python/lab-3b-cloudfront-log-explainer.py
```

![lab-3b-pt6.jpg](/Screenshots/lab-3b-pt6.jpg)
![lab-3b-pt7.jpg](/Screenshots/lab-3b-pt7.jpg)
![lab-3b-pt8.jpg](/Screenshots/lab-3b-pt8.jpg)
![lab-3b-pt9.jpg](/Screenshots/lab-3b-pt9.jpg)

---

## Step 4 – Manual Files

### [00-architecture-summary.md](audit-pack/00-architecture-summary.md)

Create or update this file manually in `audit-pack/`.  
Use the content you already have, or refine it to include:

- Regions and data residency
- Compute in sa-east-1 only
- TGW peering for network corridor
- CloudFront edge protection (custom header + no direct ALB access)
- CloudTrail for change tracking
- Note that WAF is not implemented (optional/deliverable skipped)

### [01-data-residency-proof.txt](audit-pack/01-data-residency-proof.txt)

Contains the output from the residency proof script.
This will include:

- RDS instances only in ap-northeast-1
- No RDS instances in sa-east-1

### [02-edge-proof-cloudfront.txt](audit-pack/02-edge-proof-cloudfront.txt)

Contains the output from the CloudFront log explainer script.
This will include:

- Cache Hit / Miss / RefreshHit statistics
- Sample log lines demonstrating cache behavior

### [03-waf-proof.txt](audit-pack/03-waf-proof.txt)

Contains the output from the WAF summary script.
If WAF logging is not configured, this file should note that the deliverable is optional.

### [04-cloudtrail-change-proof.txt](audit-pack/04-cloudtrail-change-proof.txt)

Contains the output from the CloudTrail last changes script.

### [05-network-corridor-proof.txt](audit-pack/05-network-corridor-proof.txt)

Contains the output from the TGW corridor proof script.
This will include:

- TGW attachments and cross-region routing details
- Verification that compute in sa-east-1 accesses RDS in ap-northeast-1 via TGW
- No direct access to RDS from sa-east-1
- Confirmation of controlled routing policies

---

## Step 5 – Final Checks & Submission

- Verify all files exist in `audit-pack/`
- Open `audit-pack/evidence.json` and ensure it looks correct
- Zip the `audit-pack/` folder if required by submission instructions
- Submit the zip file or folder as Deliverable A, along with the auditor narrative as Deliverable B

---

## [Auditor Narrative](audit-pack/auditor-narrative.txt) (Deliverable B)

This architecture adheres to APPI principles by ensuring personal health information (PHI) is stored exclusively in **Shinjuku (ap-northeast-1)**, while **Liberdade (sa-east-1)** provides stateless application compute for geographically distributed in **Shinjuku (ap-northeast-1)**, preventing unauthorized cross-border data transfers. The RDS database resides solely in **Shinjuku**, with no replication or instances in **Liberdade (sa-east-1)**, as verified by residency proofs. Compute resources in `sa-east-1` handle processing via secure **TGW** peering, maintaining global access without global storage. Placing the database overseas would violate APPI's data localization requirements, risking fines and data sovereignty issues. Audit trails from **CloudTrail and WAF logs** confirm tamper-resistant monitoring. Network corridors via **TGW** enforce controlled routing, while **CloudFront and WAF** provide edge security against direct access. Retention policies with **S3** and **CloudTrail**versioning ensure immutability. Overall, this setup prioritizes proof over operation for regulatory compliance.

---
