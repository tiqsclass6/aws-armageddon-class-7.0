# 🛡️ AWS Lab 2B (BAM B) - Honors +

![AWS](https://img.shields.io/badge/AWS-CloudFront-orange)
![Terraform](https://img.shields.io/badge/Terraform-IaC-623CE4)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)
![BAM](https://img.shields.io/badge/BAM-Honors++-gold)

---

## 📌 Task Overview

This lab demonstrates **enterprise‑grade CloudFront cache management** using a *controlled invalidation* workflow. The goal is to reinforce best practices by **preferring versioned static assets** and reserving CloudFront invalidations for rare, documented **“break‑glass” events** only.

The implementation proves correctness using HTTP headers (`Age`, `X‑Cache`) and enforces a minimal blast radius during cache purges.

---

## 🎯 Task Requirements

### Core Objectives

* Keep **origin‑driven caching** for `/api/public-feed`
* Use **versioned static assets** for normal deployments
* Perform CloudFront invalidation **only for break‑glass events**
* Prove cache behavior with headers before and after invalidation

### Non‑Negotiable Rules

1. ❌ Never invalidate `/*` during normal deployments
2. ✅ Prefer versioned assets (e.g., `app.<hash>.js`)
3. 🎯 Invalidate the smallest possible path (e.g., `/static/index.html`)
4. 💰 Be aware of invalidation cost limits (1,000 paths/month free)

---

## 🗂️ Project Structure

```plaintext
lab-2b-bam-b/
├── Screenshots/
|   ├── cloudfront-invalidations.jpg
|   ├── lab-2b-bam-b-pt1.jpg
|   ├── lab-2b-bam-b-pt2.jpg
|   ├── lab-2b-bam-b-pt3.jpg
|   ├── lab-2b-bam-b-pt4.jpg
|   ├── lab-2b-bam-b-pt5.jpg
|   ├── lab-2b-bam-b-pt6.jpg
|   ├── lab-2b-bam-b-pt7.jpg
|   ├── lab-2b-bam-b-pt8.jpg
|   ├── lab-2b-bam-b-pt9.jpg
|   ├── lab-2b-bam-b-pt10.jpg
|   ├── terraform-init-fmt-validate.jpg
|   ├── terraform-plan.jpg
|   ├── terraform-apply.jpg
|   └── terraform-destroy.jpg
├── .gitignore
├── 1-versions.tf
├── 2-providers.tf
├── 3-locals.tf
├── 4-main.tf
├── 5-variables.tf
├── 6-outputs.tf
├── README.md
├── user_data.sh
└── WRITTEN.md
```

---

## 🚀 Terraform Deployment Steps

```bash
terraform init
terraform validate
terraform plan
terraform apply
```

![terraform-init-fmt-validate](Screenshots/terraform-init-fmt-validate.jpg)
![terraform-plan](Screenshots/terraform-plan.jpg)
![terraform-apply](Screenshots/terraform-apply.jpg)

---

## 🧯 BAM Honors++ — Break‑Glass Invalidation

### Manual CLI (Approved Workflow)

```bash
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --invalidation-batch '{
    "Paths": { "Quantity": 1, "Items": ["/static/index.html"] },
    "CallerReference": "manual-break-glass-<timestamp>"
  }'
```

### Track Completion

```bash
aws cloudfront get-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --id <INVALIDATION_ID>
```

---

## 🔍 Correctness Proof (Cache Validation)

### Before Invalidation

```bash
curl -i https://<CF_DOMAIN>/static/index.html | sed -n '1,30p'
curl -i https://<CF_DOMAIN>/static/index.html | sed -n '1,30p'
```

**Expected:**

* `Age` increases
* `X‑Cache: Hit from cloudfront`

### After Invalidation

```bash
curl -i https://<CF_DOMAIN>/static/index.html | sed -n '1,30p'
```

**Expected:**

* `X‑Cache: Miss` or `RefreshHit`
* `Age` reset

---

## 📸 BAM Honors++ Screenshots

The following screenshots and recordings provide end-to-end evidence of correct CloudFront caching behavior, controlled invalidation, and Terraform lifecycle operations.

### Cache Behavior & Application Flow

* ![`lab-2b-bam-b-pt1.jpg`](/Screenshots/lab-2b-bam-b-pt1.jpg)
* ![`cloudfront-invalidations.jpg`](/Screenshots/cloudfront-invalidations.jpg)
* ![`lab-2b-bam-b-pt2.jpg`](/Screenshots/lab-2b-bam-b-pt2.jpg)
* ![`lab-2b-bam-b-pt3.jpg`](/Screenshots/lab-2b-bam-b-pt3.jpg)
* ![`lab-2b-bam-b-pt4.jpg`](/Screenshots/lab-2b-bam-b-pt4.jpg)
* ![`lab-2b-bam-b-pt5.jpg`](/Screenshots/lab-2b-bam-b-pt5.jpg)
* ![`lab-2b-bam-b-pt6.jpg`](/Screenshots/lab-2b-bam-b-pt6.jpg)
* ![`lab-2b-bam-b-pt7.jpg`](/Screenshots/lab-2b-bam-b-pt7.jpg)
* ![`lab-2b-bam-b-pt8.jpg`](/Screenshots/lab-2b-bam-b-pt8.jpg)
* ![`lab-2b-bam-b-pt9.jpg`](/Screenshots/lab-2b-bam-b-pt9.jpg)
* ![`lab-2b-bam-b-pt10.jpg`](/Screenshots/lab-2b-bam-b-pt10.jpg)

---

## 🧯 Incident Scenario — Stale `/static/index.html`

**Incident Summary:**
After a deployment, users continued to receive a stale `/static/index.html` from CloudFront, causing the application to reference outdated versioned assets. Static asset caching was functioning correctly, but the HTML entrypoint remained cached at the edge.

**Response Actions:**
Caching behavior was confirmed by observing increasing `Age` values and `X-Cache: Hit from cloudfront`. Because only the entrypoint was stale, a break-glass invalidation was executed **only** for `/static/index.html`, avoiding a full distribution purge. Once the invalidation completed, CloudFront began serving the updated entrypoint, confirmed by a cache miss/refresh and reset `Age` header.

**Outcome:**
Service was restored without unnecessary cache disruption, validating the controlled invalidation strategy.

---

## 🧹 Terraform Teardown

```bash
terraform destroy
```

![terraform-destroy](Screenshots/terraform-destroy.jpg)

---

## 🛠️ Troubleshooting

| Issue                             | Cause                            | Resolution                        |
| --------------------------------- | -------------------------------- | --------------------------------- |
| `InvalidArgument` on invalidation | Windows CRLF / `--paths` parsing | Use `--invalidation-batch`        |
| 404 on `/static/*`                | Wildcards invalid in HTTP        | Request concrete object only      |
| No SSM access                     | Missing agent or endpoints       | Install SSM agent + VPC endpoints |
| Cache not updating                | Wrong path invalidated           | Verify real entrypoint URL        |

---

## 📚 References

* **AWS CloudFront Invalidation Guide** - [https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Invalidation.html)

* **Specifying Objects for Invalidation** - [https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/invalidation-specifying-objects.html](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/invalidation-specifying-objects.html)

* **CloudFront Cache Statistics**
  [https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/invalidation-specifying-objects.html](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/invalidation-specifying-objects.html)

* **CloudFront Cache Statistics** - [https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cache-statistics.html](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cache-statistics.html)

* **CloudFront Standard Logs Reference** -
  [https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cache-statistics.html](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/cache-statistics.html)

---

## 👤 Author

* **Author:** T.I.Q.S.
* **Group Leader:** John Sweeney

---
