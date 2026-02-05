# 🏥 Lab 3A — Cross‑Region Healthcare Architecture (Shinjuku ↔ Liberdade)

![Terraform](https://img.shields.io/badge/Terraform-Validated-7B42BC?logo=terraform)
![Security](https://img.shields.io/badge/Security-Compliance--by--Design-green)
![AWS](https://img.shields.io/badge/AWS-Multi--Region-orange?logo=amazonaws)
![CloudFront](https://img.shields.io/badge/CDN-CloudFront-yellowgreen)
![MySQL](https://img.shields.io/badge/Database-MySQL-blue)
![RDS](https://img.shields.io/badge/Database-RDS-blueviolet)
![Transit-Gateway](https://img.shields.io/badge/Networking-Transit--Gateway-lightblue)
![Healthcare](https://img.shields.io/badge/Industry-Healthcare-red)
![HIPAA](https://img.shields.io/badge/Compliance-HIPAA-purple)
![No-PHI](https://img.shields.io/badge/Data-No--PHI--Outside--Shinjuku-red)

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

* **Two AWS regions**

  * **Shinjuku (Primary / Data Authority)**
  * **Liberdade (Secondary / Compute Only)**
* Single global entry point using **CloudFront**
* Cross‑region private connectivity using **Transit Gateway**
* **No databases, replicas, or PHI storage outside Shinjuku**
* Stateless compute in Liberdade
* Enforced **ALB origin verification**
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

## 🖼️ Lab 3A Demo

[Lab 3A Demo](https://github.com/user-attachments/assets/8b85866b-ab09-49d6-8837-8fde3c2d9d39)

---

## 📦 Deliverables

### **Lab 3A Screenshots**

| Deliverable      | Lab | Screenshots                                      |
|:----------------:|:---:|:------------------------------------------------:|
| `lab-3a-pt1.jpg` | 3A  | ![lab-3a-pt1.jpg](Screenshots/lab-3a-pt1.jpg)    |
| `lab-3a-pt2.jpg` | 3A  | ![lab-3a-pt2.jpg](Screenshots/lab-3a-pt2.jpg)    |
| `lab-3a-pt3.jpg` | 3A  | ![lab-3a-pt3.jpg](Screenshots/lab-3a-pt3.jpg)    |
| `lab-3a-pt4.jpg` | 3A  | ![lab-3a-pt4.jpg](Screenshots/lab-3a-pt4.jpg)    |
| `lab-3a-pt5.jpg` | 3A  | ![lab-3a-pt5.jpg](Screenshots/lab-3a-pt5.jpg)    |
| `lab-3a-pt6.jpg` | 3A  | ![lab-3a-pt6.jpg](Screenshots/lab-3a-pt6.jpg)    |
| `lab-3a-pt7.jpg` | 3A  | ![lab-3a-pt7.jpg](Screenshots/lab-3a-pt7.jpg)    |
| `lab-3a-pt8.jpg` | 3A  | ![lab-3a-pt8.jpg](Screenshots/lab-3a-pt8.jpg)    |
| `lab-3a-pt9.jpg` | 3A  | ![ lab-3a-pt9.jpg](Screenshots/lab-3a-pt9.jpg)   |
| `lab-3a-pt10.jpg`| 3A  | ![lab-3a-pt10.jpg](Screenshots/lab-3a-pt10.jpg)  |
| `lab-3a-pt11.jpg`| 3A  | ![lab-3a-pt11.jpg](Screenshots/lab-3a-pt11.jpg)  |
| `lab-3a-pt12.jpg`| 3A  | ![lab-3a-pt12.jpg](Screenshots/lab-3a-pt12.jpg)  |
| `lab-3a-pt13.jpg`| 3A  | ![lab-3a-pt13.jpg](Screenshots/lab-3a-pt13.jpg)  |
| `lab-3a-pt14.jpg`| 3A  | ![lab-3a-pt14.jpg](Screenshots/lab-3a-pt14.jpg)  |
| `lab-3a-pt15.jpg`| 3A  | ![ lab-3a-pt15.jpg](Screenshots/lab-3a-pt15.jpg) |
| `lab-3a-pt16.jpg`| 3A  | ![lab-3a-pt16.jpg](Screenshots/lab-3a-pt16.jpg)  |

### **Notes App Evidence**

| Deliverable      | Lab | Screenshots                                      |
|:----------------:|:---:|:------------------------------------------------:|
| `init.jpg`       | 3A  | ![init.jpg](Screenshots/init.jpg)                |
| `note1.jpg`      | 3A  | ![note1.jpg](Screenshots/note1.jpg)              |
| `note2.jpg`      | 3A  | ![note2.jpg](Screenshots/note2.jpg)              |
| `note3.jpg`      | 3A  | ![note3.jpg](Screenshots/note3.jpg)              |
| `note4.jpg`      | 3A  | ![note4.jpg](Screenshots/note4.jpg)              |
| `note5.jpg`      | 3A  | ![note5.jpg](Screenshots/note5.jpg)              |
| `note6.jpg`      | 3A  | ![note6.jpg](Screenshots/note6.jpg)              |
| `list.jpg`       | 3A  | ![list.jpg](Screenshots/list.jpg)                |

### **Liberdade Infrastructure Evidence**

| Deliverable                   |Lab | Screenshots                                                                 |
|:-----------------------------:|:--:|:---------------------------------------------------------------------------:|
|`liberdade-cf-pt1.jpg`         | 3A | ![liberdade-cf-pt1.jpg](Screenshots/liberdade-cf-pt1.jpg)                   |
|`liberdade-cf-pt2.jpg`         | 3A | ![liberdade-cf-pt2.jpg](Screenshots/liberdade-cf-pt2.jpg)                   |
|`liberdade-cf-pt3.jpg`         | 3A | ![liberdade-cf-pt3.jpg](Screenshots/liberdade-cf-pt3.jpg)                   |
|`liberdade-lb-pt1.jpg`         | 3A | ![liberdade-lb-pt1.jpg](Screenshots/liberdade-lb-pt1.jpg)                   |
|`liberdade-lb-pt2.jpg`         | 3A | ![liberdade-lb-pt2.jpg](Screenshots/liberdade-lb-pt2.jpg)                   |
|`liberdade-ec2-instances.jpg`  | 3A | ![liberdade-ec2-instances.jpg](Screenshots/liberdade-ec2-instances.jpg)     |
|`liberdade-security-groups.jpg`| 3A | ![liberdade-security-groups.jpg](Screenshots/liberdade-security-groups.jpg) |
|`liberdade-tg.jpg`             | 3A | ![liberdade-tg.jpg](Screenshots/liberdade-tg.jpg)                           |
|`liberdade-tgw-rt-pt1.jpg`     | 3A | ![liberdade-tgw-rt-pt1.jpg](Screenshots/liberdade-tgw-rt-pt1.jpg)           |
|`liberdade-tgw-rt-pt2.jpg`     | 3A | ![liberdade-tgw-rt-pt2.jpg](Screenshots/liberdade-tgw-rt-pt2.jpg)           |

### **Shinjuku Infrastructure Evidence**

| Deliverable                   |Lab | Screenshots                                                                 |
|:-----------------------------:|:--:|:---------------------------------------------------------------------------:|
|`shinjuku-rds-pt1.jpg`         | 3A | ![shinjuku-rds-pt1.jpg](Screenshots/shinjuku-rds-pt1.jpg)                   |
|`shinjuku-rds-pt2.jpg`         | 3A | ![shinjuku-rds-pt2.jpg](Screenshots/shinjuku-rds-pt2.jpg)                   |
|`shinjuku-secrets.jpg`         | 3A | ![shinjuku-secrets.jpg](Screenshots/shinjuku-secrets.jpg)                   |
|`shinjuku-ssm.jpg`             | 3A | ![shinjuku-ssm.jpg](Screenshots/shinjuku-ssm.jpg)                           |
|`shinjuku-tgw-rt-pt1.jpg`      | 3A | ![shinjuku-tgw-rt-pt1.jpg](Screenshots/shinjuku-tgw-rt-pt1.jpg)             |
|`shinjuku-tgw-rt-pt2.jpg`      | 3A | ![shinjuku-tgw-rt-pt2.jpg](Screenshots/shinjuku-tgw-rt-pt2.jpg)             |
|`cloudwatch-logs.jpg`          | 3A | ![cloudwatch-logs.jpg](Screenshots/cloudwatch-logs.jpg)                     |

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

Detailed commands are provided in **[STEPS.md](STEPS.md)**.

---

## 📚 References

* [AWS Transit Gateway Documentation](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html)
* [AWS Well-Architected Framework — Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
* [AWS Healthcare & HIPAA Compliance Whitepapers](https://aws.amazon.com/compliance/hipaa-compliance/)
* [Amazon RDS Security Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SecurityBestPractices.html)
* [CloudFront Security & Origin Protection](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/security-overview.html)

---

## **Authors**

* **Author:** T.I.Q.S.
* **Group Leader:** John Sweeney

---
