# Lab 1C – Bonus E  (WAF Logging Verification (CLI Only))

---

## A) Confirm WAF logging is enabled

```bash
aws wafv2 get-logging-configuration \
  --resource-arn arn:aws:wafv2:us-east-1:866340886126:regional/webacl/lab-1c-waf/e118dcd8-9cd4-4e2b-a5d0-5d72ecff4396
```

![bonus-e-pt1.jpg](/Screenshots/bonus-e-pt1.jpg)

Expected:

* `LogDestinationConfigs` contains exactly **one** destination

---

## B) Generate traffic (hits + blocks)

```bash
curl -I https://theinternationalquietstorm.com/
curl -I https://app.theinternationalquietstorm.com/
```

![bonus-e-pt2.jpg](/Screenshots/bonus-e-pt2.jpg)

---

## C) Inspect CloudWatch Logs

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
