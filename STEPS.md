# Lab 1C — Bonus H: Bedrock Auto-Generated Incident Reports

> Region: us-east-1  
> Account: <INSERT_HERE>  
> Report Bucket: lab-1c-bonus-h-ir-<ACCOUNT_ID>  
> Reports Prefix: reports/  
> Function: lab-1c-bonus-h-incident-reporter  
> Topic: arn:aws:sns:us-east-1:<ACCOUNT_ID>:lab-1c-db-incidents  
> Incident ID used in this run: bonus_h-20260209T171922Z-97e21858

---

## 1) Confirm Lambda exists + configuration

```bash
aws lambda get-function \
  --function-name lab-1c-bonus-h-incident-reporter \
  --query 'Configuration.[FunctionName,Runtime,Timeout,MemorySize]' \
  --output table
```

---

## 2) Confirm Lambda is subscribed to the incident SNS topic

```bash
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:<ACCOUNT_ID>:lab-1c-db-incidents \
  --query 'Subscriptions[].Endpoint'
```

![bonus-h-pt1.jpg](/Screenshots/bonus-h-pt1.jpg)

---

## 3) Trigger the Lambda (Fake Alarm Event)

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

---

## 4) Confirm report artifacts exist in S3 (md + json)

```bash
aws s3 ls s3://lab-1c-bonus-h-ir-<ACCOUNT_ID>/reports/ --recursive | tail
```

![bonus-h-pt2.jpg](/Screenshots/bonus-h-pt2.jpg)
[**Lambda Test Report (Markdown)**](/deliverables/lambda-test-bonus-h.md)

---

## 5) Download the human incident report (Markdown)

```bash
aws s3 cp \
  s3://lab-1c-bonus-h-ir-<ACCOUNT_ID>/reports/bonus_h-20260209T171922Z-97e21858.md \
  lambda-test-bonus-h.md
```

---

## 6) Validate evidence bundle contains NO secrets (password check)

```bash
aws s3 cp \
  s3://lab-1c-bonus-h-ir-<ACCOUNT_ID>/reports/bonus_h-20260209T171922Z-97e21858.json \
  - | grep -i password && echo FAIL
```

---

## 7) Download the evidence bundle (JSON)

```bash
aws s3 cp \
  s3://lab-1c-bonus-h-ir-<ACCOUNT_ID>/reports/bonus_h-20260209T171922Z-97e21858.json \
  lambda-test-bonus-h.json
```

![bonus-h-pt3.jpg](/Screenshots/bonus-h-pt3.jpg)
[**Lambda Test Report (JSON)**](/deliverables/lambda-test-bonus-h.json)

---
