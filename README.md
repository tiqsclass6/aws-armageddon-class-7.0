# 🛡️ AWS Lab 2A — CloudFront Origin Cloaking with WAF & ALB

![AWS](https://img.shields.io/badge/AWS-Architecture-232F3E?logo=amazon-aws&logoColor=white)
![CloudFront](https://img.shields.io/badge/CloudFront-Edge%20Security-orange?logo=amazon-aws)
![WAF](https://img.shields.io/badge/AWS-WAF%20v2-red?logo=amazon-aws)
![ALB](https://img.shields.io/badge/Application%20Load%20Balancer-Origin%20Only-blue?logo=amazon-aws)
![Route53](https://img.shields.io/badge/Route%2053-DNS%20Front%20Door-1E88E5?logo=amazon-aws)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.9-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io)
[![AWS Provider](https://img.shields.io/badge/AWS%20Provider-~%3E%206.0-FF9900?logo=amazon-aws&logoColor=white)](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 🔐 Overview

This lab implements a **defense-in-depth CloudFront cloaking architecture** where:

- **CloudFront is the only public entry point**
- The **Application Load Balancer (ALB) is fully hidden**
- **WAF protections are enforced at the edge**
- Origin access is restricted using **secret headers + AWS-managed prefix lists**

> *“Only the front door is visible. Everything behind it stays private.”*

---

## 🎯 Task Objectives

- Force **all internet traffic** through CloudFront
- Prevent **direct ALB access**, even if the DNS name is known
- Enforce **origin authentication** using a custom HTTP header
- Validate **CloudFront anycast behavior** via DNS
- Demonstrate **real-world origin cloaking patterns**

---

## 🧱 Architecture Requirements

- **Internet → CloudFront (+ WAF) → ALB → Private EC2 → RDS**
- ALB **not reachable** from the public internet
- WAF scoped to **CloudFront**, not the ALB
- Route 53 apex + subdomain → **CloudFront only**
- ACM certificates:
  - `us-east-1` → CloudFront
  - `us-east-2` → ALB
- ALB security group allows traffic **only from CloudFront**
- Listener rule enforces secret header:
  - `X-Lab2a-Origin-Secret`
- Origin cloaking using AWS-managed **CloudFront prefix list**
- Verification:
  - ❌ Direct ALB curl fails
  - ✅ CloudFront curl succeeds
  - ✅ `dig` returns CloudFront anycast IPs

---

## 🗂️ Project Structure

```plaintext
lab-2a/
├── Screenshots/
│   ├── alb-pt1.jpg
│   ├── alb-pt2.jpg
│   ├── cloudfront-cloak-full.jpg
│   ├── cloudfront-distro.jpg
│   ├── lab-2a-pt1.jpg
│   ├── lab-2a-pt2.jpg
│   ├── lab-2a-pt3.jpg
│   ├── route-53.jpg
│   ├── terraform-apply.jpg
│   ├── terraform-destroy.jpg
│   ├── terraform-init-fmt-validate.jpg
│   ├── terraform-plan.jpg
│   └── waf.jpg
│
├── .gitignore
├── 1-versions.tf
├── 2-providers.tf
├── 3-locals.tf
├── 4-main.tf
├── 5-variables.tf
├── 6-outputs.tf
├── germany.sh
├── README.md
├── STEPS.md
└── WRITTEN.md
````

---

## 🚀 Terraform Deployment

### 1️⃣ Prerequisites

- AWS CLI configured
- ACM certificates issued:

  - **CloudFront:** `us-east-1`
  - **ALB:** `us-east-2`
- Route 53 public hosted zone:

  - `theinternationalquietstorm.com`

---

### 2️⃣ Initialize

```bash
terraform init
terraform fmt
terraform validate
```

![terraform-init-fmt-validate](/Screenshots/terraform-init-fmt-validate.jpg)

---

### 3️⃣ Plan

```bash
terraform plan
```

![terraform-plan](/Screenshots/terraform-plan.jpg)

---

### 4️⃣ Apply

```bash
terraform apply
```

![terraform-apply](/Screenshots/terraform-apply.jpg)

---

### 5️⃣ Verification

```bash
# Direct ALB (should fail)
curl -I https://$(terraform output -raw alb_dns_name)

# CloudFront (should succeed)
curl -I https://theinternationalquietstorm.com
curl -I https://app.theinternationalquietstorm.com

# DNS anycast check
dig theinternationalquietstorm.com +short
```

---

## 🔍 Lab Demos

- **CloudFront Origin `theinternationalquietstorm.com`**

    <https://github.com/user-attachments/assets/28bbea7b-9674-4456-9479-4608c3cd8467>

- **CloudFront Subdomain `app.theinternationalquietstorm.com`**

    <https://github.com/user-attachments/assets/36d69cc8-5b9d-493b-946e-e42b9af70f17>

- **WAF Configuration**

    <https://github.com/user-attachments/assets/8ec1531d-64ff-4cce-87a0-17ab7daf6369>

---

## 📦 Deliverables

|Deliverables                 | Description                                                                    | Screenshot                                                           |
|-----------------------------|--------------------------------------------------------------------------------|----------------------------------------------------------------------|
| `cloudfront-cloak-full.jpg` | CloudFront distribution configuration showing origin cloaking with prefix list | ![cloudfront-cloak-full.jpg](/Screenshots/cloudfront-cloak-full.jpg) |
| `alb-pt1.jpg`               | ALB security group showing no inbound rules from outside                       | ![alb-pt1.jpg](/Screenshots/alb-pt1.jpg)                             |
| `alb-pt2.jpg`               | ALB listener rule showing secret header requirement                            | ![alb-pt2.jpg](/Screenshots/alb-pt2.jpg)                             |
| `cloudfront-distro.jpg`     | CloudFront distribution configuration showing WAF                              | ![cloudfront-distro.jpg](/Screenshots/cloudfront-distro.jpg)         |
| `route-53.jpg`              | Route 53 records showing apex and subdomain pointing to CloudFront             | ![route-53.jpg](/Screenshots/route-53.jpg)                           |
| `waf.jpg`                   | WAF Web ACL configuration showing rules and CloudFront association             | ![waf.jpg](/Screenshots/waf.jpg)                                     |

---

## 🧹 Teardown

```bash
terraform destroy
```

![terraform-destroy](/Screenshots/terraform-destroy.jpg)

> ⚠️ CloudFront distributions may take **10–30 minutes** to fully delete.

---

## 📚 References

- AWS CloudFront Alternate Domain Names
  [https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/CNAMEs.html](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/CNAMEs.html)
- Restricting ALB Access to CloudFront
  [https://aws.amazon.com/blogs/networking-and-content-delivery/restricting-access-to-application-load-balancers/](https://aws.amazon.com/blogs/networking-and-content-delivery/restricting-access-to-application-load-balancers/)
- AWS WAFv2 (CloudFront Scope)
  [https://docs.aws.amazon.com/waf/latest/developerguide/waf-cloudfront.html](https://docs.aws.amazon.com/waf/latest/developerguide/waf-cloudfront.html)
- AWS Managed Prefix Lists
  [https://docs.aws.amazon.com/vpc/latest/userguide/aws-managed-prefix-lists.html](https://docs.aws.amazon.com/vpc/latest/userguide/aws-managed-prefix-lists.html)

---

## 🛠️ Troubleshooting

- **InvalidViewerCertificate** → Wait for ACM propagation
- **SSLPolicyNotFound** → Use `ELBSecurityPolicy-TLS13-1-2-2021-06`
- **WAF scope error** → Ensure Web ACL is created in `us-east-1`
- **ACM lookup empty** → Certificate must be `ISSUED` and domain-exact

---

## 👤 Authors

- **Author:** T.I.Q.S.
- **Group Lead:** John Sweeney
