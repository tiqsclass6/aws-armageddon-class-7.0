# AWS Lab 1C – Bonus C

This document contains **CLI verification commands** used to confirm that the infrastructure meets all lab requirements.

Run commands from a machine with:

- AWS CLI installed
- Appropriate IAM read permissions
- Correct AWS region set

---

## 1️⃣ Confirm Hosted Zone Exists

```bash
aws route53 list-hosted-zones-by-name \
  --dns-name theinternationalquietstorm.com \
  --query "HostedZones[].Id"
```

Expected: Hosted zone ID returned.

---

## 2️⃣ Confirm Route53 Record Exists

```bash
aws route53 list-resource-record-sets \
  --hosted-zone-id Z00355293CPG0LM0BIYOR \
  --query "ResourceRecordSets[?Name=='theinternationalquietstorm.com.']"
```

![bonus-c-pt1](Screenshots/bonus-c-pt1.jpg)

Expected:

- Alias A record pointing to ALB DNS name

---

## 3️⃣ Confirm ACM Certificate Is Issued

```bash
aws acm describe-certificate \
  --certificate-arn arn:aws:acm:us-east-1:866340886126:certificate/9e091531-3230-42ff-b5f4-468d0031d795 \
  --query "Certificate.Status"
```

Expected:

```text
"ISSUED"
```

---

## 4️⃣ Confirm HTTPS Connectivity

```bash
curl -I -k https://theinternationalquietstorm.com
```

![bonus-c-pt2](Screenshots/bonus-c-pt2.jpg)

Expected:

- HTTP response headers returned
- TLS handshake successful

---

## ✅ Completion Criteria

All of the following must be true:

- Hosted zone exists
- DNS record resolves
- ACM certificate is issued
- HTTPS endpoint is reachable

If any step fails, review:

- DNS delegation
- Certificate domain coverage
- Terraform state consistency

---
