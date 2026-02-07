# STEPS.md

## Direct ALB access should fail (403)

```bash
curl -I -k https://lab-2a-alb-316017758.us-east-2.elb.amazonaws.com
```

### Expected: 403 (blocked by missing header)

---

## CloudFront access should succeed

```bash
  curl -I https://theinternationalquietstorm.com
  curl -I --ssl-no-revoke https://app.theinternationalquietstorm.com
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
  --id E9CJW26HBNGTS \
  --query "Distribution.DistributionConfig.WebACLId"
```

### Expected: WebACL ARN present

---

## theinternationalquietstorm.com points to CloudFront

```bash
  dig theinternationalquietstorm.com A +short
  dig app.theinternationalquietstorm.com A +short
```

![lab-2a-pt3.jpg](/Screenshots/lab-2a-pt3.jpg)

### Expected: resolves to CloudFront (you’ll see CloudFront anycast behavior, not ALB IPs)

---
