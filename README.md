# 🛡️ AWS Lab 2B — Germany Cloak (CloudFront Front Door)

![AWS](https://img.shields.io/badge/AWS-CloudFront-orange?logo=amazonaws)
![Terraform](https://img.shields.io/badge/Terraform-IaC-844FBA?logo=terraform)
![Security](https://img.shields.io/badge/Security-Origin%20Shield-success)
![Caching](https://img.shields.io/badge/Caching-Origin--Driven-blue)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen)

> **“Only the front door is visible. Everything behind it stays private.”**

---

## 📌 Task Overview

This lab implements a **secure, production-grade CloudFront front door** that fully shields the application origin.
All public traffic enters through **CloudFront only**, while the **Application Load Balancer (ALB)** and **EC2 origin** remain protected and inaccessible directly.

The solution demonstrates:

* Origin-driven caching
* Header-gated ALB access
* HTTPS everywhere
* Proper ACM certificate placement
* CloudFront as the *only* public ingress

---

## 🎯 Task Requirements

✔ CloudFront is the **only public entry point**
✔ Direct ALB access is blocked / fails
✔ HTTPS enforced end-to-end
✔ Origin uses **origin-driven caching**
✔ Dynamic APIs are **never cached**
✔ IMDSv2 metadata is securely accessed
✔ Terraform-managed infrastructure
✔ Route53 + ACM properly configured

---

## 🧱 Project Structure

```plaintext
lab-2b-bam-a/
├── Screenshots/
|   ├── cloudfront-cache-policy-disabled-01.jpg
|   ├── cloudfront-cache-policy-static-01.jpg
|   ├── cloudfront-origin-rqst-policy-api-01.jpg
|   ├── cloudfront-response-static-01.jpg
|   ├── lab-2b-bam-a-pt1.jpg
|   ├── lab-2b-bam-a-pt2.jpg
|   ├── lab-2b-bam-a-pt3.jpg
|   ├── lab-2b-bam-a-pt4.jpg
|   ├── terraform-apply.jpg
|   ├── terraform-destroy.jpg
|   ├── terraform-init-fmt-validate.jpg
|   └── terraform-plan.jpg
|
├── .gitignore
├── 1-versions.tf
├── 2-providers.tf
├── 3-locals.tf
├── 4-main.tf
├── 5-variables.tf
├── 6-outputs.tf
├── STEPS.md
├── user_data.sh
├── README.md
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

![terraform-init-fmt-validate.jpg](/Screenshots/terraform-init-fmt-validate.jpg)
![terraform-plan.jpg](/Screenshots/terraform-plan.jpg)
![terraform-apply.jpg](/Screenshots/terraform-apply.jpg)

⏳ **Note:**
ACM DNS validation may take several minutes before CloudFront becomes fully active.

---

## 🧪 Verification (BAM Honors)

### 1️⃣ CloudFront Front Door (FAILURE)

```bash
# Direct ALB access should fail
curl -i https://app.theinternationalquietstorm.com/api/public-feed | sed -n '1,30p'
```

* Blocked or gated
* Demonstrates cloaking effectiveness

![lab-2b-bam-a-pt1.jpg](/Screenshots/lab-2b-bam-a-pt1.jpg)

---

### 2️⃣ Direct Origin Access (SUCCESS)

```bash
# Direct origin access should succeed
curl -i https://origin.theinternationalquietstorm.com
```

* Returns `200 OK`
* Shows dynamic timestamp
* Cache behavior respected

![lab-2b-bam-a-pt2.jpg](/Screenshots/lab-2b-bam-a-pt2.jpg)

---

### 3️⃣ Cache Behavior Proof

```bash
# CloudFront response should show caching headers
curl -i https://app.theinternationalquietstorm.com/api/list | sed -n '1,30p'
```

![lab-2b-bam-a-pt3.jpg](/Screenshots/lab-2b-bam-a-pt3.jpg)

```bash
curl -i https://app.theinternationalquietstorm.com/api/list | sed -n '1,30p'
```

![lab-2b-bam-a-pt4.jpg](/Screenshots/lab-2b-bam-a-pt4.jpg)

* `message_of_the_minute` changes
* `instance_id` remains consistent per origin
* `X-Cache` reflects origin-driven behavior

---

### 4️⃣ Other Screenshots

* **CloudFront cache policy disabled for dynamic API**
  * ![cloudfront-cache-policy-disabled-01.jpg](/Screenshots/cloudfront-cache-policy-disabled-01.jpg)

* **CloudFront cache policy static for static API**
  * ![cloudfront-cache-policy-static-01.jpg](/Screenshots/cloudfront-cache-policy-static-01.jpg)

* **CloudFront origin request policy forwarding all headers for dynamic API**
  * ![cloudfront-origin-rqst-policy-api-01.jpg](/Screenshots/cloudfront-origin-rqst-policy-api-01.jpg)

* **CloudFront response static for static API**
  * ![cloudfront-response-static-01.jpg](/Screenshots/cloudfront-response-static-01.jpg)

---

## 🧠 Why This Design Is Secure

### Origin-Driven Caching

Caching decisions are made by the **application**, preventing accidental storage of sensitive or user-specific data at the edge.

### Header-Gated ALB

The ALB only accepts requests with CloudFront-specific headers, eliminating direct internet abuse.

### IMDSv2 Enforcement

Metadata access requires signed tokens, protecting instance identity data.

---

## 🧨 Terraform Teardown

```bash
terraform destroy
```

![terraform-destroy.jpg](/Screenshots/terraform-destroy.jpg)

✔ Fully removes:

* CloudFront distribution
* ALB
* EC2
* Security groups
* Route53 records
* ACM certificates

---

## 🛠️ Troubleshooting

### CloudFront returns 504

* Verify ALB listener is HTTPS
* Ensure origin DNS points to ALB
* Confirm security group allows ALB → EC2

### Instance ID / Region missing

* Confirm IMDSv2 is enabled
* Validate CGI metadata proxy script
* Ensure Apache `ExecCGI` is enabled

### ACM Certificate Error

* ALB cert must be in **same region**
* CloudFront cert must be in **us-east-1**

---

## 📚 References

* CloudFront Security Best Practices
  [https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/security.html](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/security.html)

* Origin Request Policies
  [https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/controlling-origin-requests.html](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/controlling-origin-requests.html)

* Application Load Balancer Security
  [https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)

* EC2 IMDSv2
  [https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/configuring-instance-metadata-service.html)

* Terraform AWS Provider
  [https://registry.terraform.io/providers/hashicorp/aws/latest/docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

## **Authors**

* **Author:** T.I.Q.S.
* **Group Leader:** John Sweeney

---
