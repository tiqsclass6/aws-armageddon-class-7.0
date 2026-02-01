# 🏥 Lab 3A — Cross‑Region Healthcare Architecture (Shinjuku ↔ Liberdade) **(UNDER CONSTRUCTION)**

![Terraform](https://img.shields.io/badge/Terraform-Validated-7B42BC?logo=terraform)
![Security](https://img.shields.io/badge/Security-Compliance--by--Design-green)
![AWS](https://img.shields.io/badge/AWS-Multi--Region-orange?logo=amazonaws)
![ALB](https://img.shields.io/badge/Load--Balancer-ALB-orange)
![Auto-Scaling](https://img.shields.io/badge/Compute-Auto--Scaling-green)
![CloudFront](https://img.shields.io/badge/CDN-CloudFront-yellowgreen)
![EC2](https://img.shields.io/badge/Compute-EC2-lightgrey)
![MySQL](https://img.shields.io/badge/Database-MySQL-blue)
![Origin-Verification](https://img.shields.io/badge/Security-Origin--Verification-green)
![RDS](https://img.shields.io/badge/Database-RDS-blueviolet)
![Stateless](https://img.shields.io/badge/Compute-Stateless-green)
![SSM](https://img.shields.io/badge/Management-SSM-blue)
![Transit-Gateway](https://img.shields.io/badge/Networking-Transit--Gateway-lightblue)
![TGW-Peering](https://img.shields.io/badge/Networking-TGW--Peering-lightblue)
![Healthcare](https://img.shields.io/badge/Industry-Healthcare-red)
![HIPAA](https://img.shields.io/badge/Compliance-HIPAA-purple)
![No-PHI](https://img.shields.io/badge/Data-No--PHI--Outside--Shinjuku-red)
![Status](https://img.shields.io/badge/Lab-Complete-success)

---

## 📌 Lab Overview

**Lab 3A** demonstrates a production‑grade, compliance‑aware, cross‑region cloud architecture designed for regulated healthcare workloads.

The core principle of Lab 3A is:

> **Global access does not require global storage.**

All Protected Health Information (PHI) is stored exclusively in **Shinjuku (ap‑northeast‑1)**, while **Liberdade (sa‑east‑1)** provides stateless application compute for geographically distributed users. The two regions are connected using **AWS Transit Gateway with inter‑region peering**, forming a controlled and auditable data corridor.

This architecture closely mirrors real‑world AWS Healthcare / HIPAA‑aligned deployments.

---

## 🧩 Lab Requirements

The lab satisfies the following requirements:

* Two AWS regions

  * **Shinjuku (Primary / Data Authority)**
  * **Liberdade (Secondary / Compute Only)**
* Single global entry point using **CloudFront**
* Cross‑region private connectivity using **Transit Gateway**
* **No databases, replicas, or PHI storage outside Shinjuku**
* Stateless compute in Liberdade
* No SSH or bastion access (SSM only)
* Enforced ALB origin verification
* Explicit routing and security controls

---

## 🏗️ Project Structure

```plaintext
Lab-3a/
├── Screenshots/
│   ├── cloudwatch-logs.jpg
│   ├── init.jpg
│   ├── lab-3a-demo.mp4
│   ├── lab-3a-pt1.jpg
│   ├── lab-3a-pt2.jpg
│   ├── lab-3a-pt3.jpg
│   ├── lab-3a-pt4.jpg
│   ├── lab-3a-pt5.jpg
│   ├── lab-3a-pt6.jpg
│   ├── lab-3a-pt7.jpg
│   ├── lab-3a-pt8.jpg
│   ├── lab-3a-pt9.jpg
│   ├── lab-3a-pt10.jpg
│   ├── lab-3a-pt11.jpg
│   ├── lab-3a-pt12.jpg
│   ├── lab-3a-pt13.jpg
│   ├── lab-3a-pt14.jpg
│   ├── lab-3a-pt15.jpg
│   ├── lab-3a-pt16.jpg
│   ├── liberdade-cf-pt1.jpg
│   ├── liberdade-cf-pt2.jpg
│   ├── liberdade-cf-pt3.jpg
│   ├── liberdade-ec2-instances.jpg
│   ├── liberdade-lb-pt1.jpg
│   ├── liberdade-lb-pt2.jpg
│   ├── liberdade-security-groups.jpg
│   ├── liberdade-tg.jpg
│   ├── liberdade-tgw-rt-pt1.jpg
│   ├── liberdade-tgw-rt-pt2.jpg
│   ├── list.jpg
│   ├── note1.jpg
│   ├── note2.jpg
│   ├── note3.jpg
│   ├── note4.jpg
│   ├── note5.jpg
│   ├── note6.jpg
│   ├── shinjuku-rds-pt1.jpg
│   ├── shinjuku-rds-pt2.jpg
│   ├── shinjuku-secrets.jpg
│   ├── shinjuku-ssm.jpg
│   ├── shinjuku-tgw-rt-pt1.jpg
│   ├── shinjuku-tgw-rt-pt2.jpg
│   ├── terraform-apply.jpg
│   ├── terraform-destroy.jpg
│   ├── terraform-init-fmt-validate.jpg
│   └── terraform-plan.jpg
│
├── scripts/
│   ├── lab-3a.sh.tftpl
│   └── user_data.sh
│
├── 0-versions.tf
├── 1-providers.tf
├── 2-locals.tf
├── 3-data.tf
├── 4-variables.tf
├── 5a-liberdade-infrastructure.tf
├── 5b-liberdade-lb.tf
├── 5c-liberdade-cloudfront.tf
├── 5d-liberdade-tgw.tf
├── 5e-liberdade-iam.tf
├── 6a-shinjuku-infrastructure.tf
├── 6b-shinjuku-rds.tf
├── 6c-shinjuku-tgw.tf
├── 6d-shinjuku-iam.tf
├── 7-outputs.tf
│
├── README.md
├── STEPS.md
└── WRITTEN.md
```

---

## 🚀 Terraform Deployment Steps

> ⚠️ **Prerequisite:** AWS credentials configured with sufficient permissions

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

![terraform-init-fmt-validate](Screenshots/terraform-init-fmt-validate.jpg)
![terraform-plan](Screenshots/terraform-plan.jpg)

Successful deployment results in:

* CloudFront distribution
* Application Load Balancer in Liberdade
* Auto Scaling Group of EC2 instances
* Transit Gateway peering between regions
* RDS MySQL instance in Shinjuku

![terraform-apply](Screenshots/terraform-apply.jpg)

---

## 📦 Deliverables

The lab delivers the following artifacts:

* ✅ Fully deployed multi‑region AWS infrastructure
* ✅ Verified TGW inter‑region routing
* ✅ Functional application with cross‑region writes
* ✅ No PHI storage outside Shinjuku
* ✅ Screenshots proving each verification step
* ✅ `WRITTEN.md` — architectural & compliance explanation
* ✅ `STEPS.md` — reproducible verification runbook

---

## 🖼️ Additional Screenshots

Screenshots included demonstrate:

* Terraform init / validate / plan
* Successful `terraform apply`
* ALB target health
* TGW attachments and routes
* RDS connectivity from Liberdade via TGW
* CloudFront application responses

See the `Screenshots/` directory for full evidence.

---

## 🧨 Terraform Teardown

To remove all deployed resources:

```bash
terraform destroy
```

This will fully decommission:

* VPCs
* Transit Gateways
* CloudFront
* ALB
* EC2 instances
* RDS

![terraform-destroy](Screenshots/terraform-destroy.jpg)

---

## 🛠️ Troubleshooting Steps

Common checks if issues occur:

* Verify TGW attachments are **available** in both regions
* Confirm VPC route tables contain cross‑region CIDRs
* Ensure RDS Security Group allows Liberdade VPC CIDR on 3306
* Confirm ALB rules require CloudFront origin header
* Validate SSM endpoints exist and are reachable

Detailed commands are provided in **STEPS.md**.

---

## 📚 References

* AWS Transit Gateway Documentation
* AWS Well‑Architected Framework — Security Pillar
* AWS Healthcare & HIPAA Compliance Whitepapers
* Amazon RDS Security Best Practices
* CloudFront Security & Origin Protection

---

## ✍️ Authors

**T.I.Q.S.**

---
