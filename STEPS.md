# Lab 2B — Command Execution Steps

## Static Cache Proof

```bash
curl -I -k https://app.theinternationalquietstorm.com/static/example.txt
curl -I -k https://app.theinternationalquietstorm.com/static/example.txt
```

![lab-2b-deliverable-b-pt1](Screenshots/lab-2b-deliverable-b-pt1.jpg)

---

## API Non-Cache Proof

```bash
curl -I -k https://app.theinternationalquietstorm.com/api/list
curl -I -k https://app.theinternationalquietstorm.com/api/list
```

![lab-2b-deliverable-b-pt2](Screenshots/lab-2b-deliverable-b-pt2.jpg)

---

## Query String Cache Key Test

```bash
curl -I -k "https://<cloudfront-domain>/static/example.txt?v=1"
curl -I -k "https://<cloudfront-domain>/static/example.txt?v=2"
```

![lab-2b-deliverable-d-pt2](Screenshots/lab-2b-deliverable-d-pt2.jpg)

---

## DNS Verification

```bash
nslookup theinternationalquietstorm.com 8.8.8.8
nslookup app.theinternationalquietstorm.com 8.8.8.8
nslookup www.theinternationalquietstorm.com 8.8.8.8
```

![lab-2b-deliverable-d-pt3](Screenshots/lab-2b-deliverable-d-pt3.jpg)

---

## Optional Resolver Bypass

```bash
curl -I -k https://<cloudfront-domain>/static/example.txt
curl -I -k https://<cloudfront-domain>/api/list
```

![lab-2b-deliverable-d-pt1](Screenshots/lab-2b-deliverable-d-pt1.jpg)

---
