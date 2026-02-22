# Lab 2A: WAF Migration Validation Deliverables

## Direct ALB access should fail (403)

```bash
curl -I https://lab-2a-alb-1021479830.us-east-1.elb.amazonaws.com
```

### Expected: 403 (blocked by missing header)

---

## CloudFront access should succeed

```bash
  curl -I -k https://theinternationalquietstorm.com
  curl -I -k https://app.theinternationalquietstorm.com
```

### Expected: 200/301 → 200

![la-2a-pt1.jpg](/Screenshots/lab-2a-pt1.jpg)

---

## WAF moved to CloudFront

```bash
  aws wafv2 get-web-acl \
  --name lab-2a-cf-waf \
  --scope CLOUDFRONT \
  --id 62e09208-544b-4d51-ac84-46e8cc4944ba
```

![lab-2a-pt2.jpg](/Screenshots/lab-2a-pt2.jpg)

### And confirm distribution references it

---

```bash
  aws cloudfront get-distribution \
  --id EVKGK9OT7KQ3Y \
  --query "Distribution.DistributionConfig.WebACLId" \
  --output text
```

### Expected: WebACL ARN present

---

## `theinternationalquietstorm.com` points to CloudFront

```bash
  dig theinternationalquietstorm.com A +short
  dig app.theinternationalquietstorm.com A +short
```

![lab-2a-pt3.jpg](/Screenshots/lab-2a-pt3.jpg)

### Expected: resolves to CloudFront (you’ll see CloudFront anycast behavior, not ALB IPs)

---
