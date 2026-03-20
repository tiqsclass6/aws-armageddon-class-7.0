# 🏥 AWS Lab 3B — Audit Evidence & Regulator-Ready Logging

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

**Lab 3B** demonstrates a production‑grade, compliance‑aware, cross‑region cloud architecture designed for regulated healthcare workloads.

The core principle of Lab 3B is:

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
Lab-3b/
├── audit-pack/
│   ├── 00-architecture-summary.md
│   ├── 01-data-residency-proof.txt
│   ├── 02-edge-proof-cloudfront.txt
│   ├── 03-waf-proof.txt
│   ├── 04-cloudtrail-change-proof.txt
│   ├── 05-network-corridor-proof.txt
│   └── auditor-narrative.txt
│
├── deliverables/
│   ├── cloudfront-part1.log
│   ├── cloudfront-part2.log
│   ├── cloudfront-log.gz
│   └── realtime-logs.jsonl
│
├── python/
│   ├── lab-3b-cloudfront-log-explainer.py
│   ├── lab-3b-cloudtrail_last-changes.py
│   ├── lab-3b-residency-proof.py
│   ├── lab-3b-tgw-corridor-proof.py
│   └── lab-3b-waf-summary.py
│
├── s3-cloudfront-logs/
│   ├── E3OM7PTY6WT13S.2026-02-04-02.1a158131.gz
│   ├── E3OM7PTY6WT13S.2026-02-04-02.e863dd94.gz
│   ├── E3OM7PTY6WT13S.2026-02-04-03.c44d7710.gz
│   ├── E3OM7PTY6WT13S.2026-02-04-04.3ed5a992.gz
│   ├── E10X0OSMS6FBZJ.2026-02-03-07.791fbc24.gz
│   ├── E10X0OSMS6FBZJ.2026-02-03-07.8032d878.gz
│   ├── E10X0OSMS6FBZJ.2026-02-03-07.1204425a.gz
│   ├── E10X0OSMS6FBZJ.2026-02-03-07.b0c28b2e.gz
│   ├── E10X0OSMS6FBZJ.2026-02-03-07.eb3ac25c.gz
│   ├── E27IOBC69KWMUQ.2026-02-05-02.3baf0202.gz
│   ├── E27IOBC69KWMUQ.2026-02-05-02.8f418558.gz
│   └── E27IOBC69KWMUQ.2026-02-05-02.9bc373c1.gz|
|
├── Screenshots/
│   ├── lab-3b-demo.mp4
│   ├── lab-3b-pt1.jpg
│   ├── lab-3b-pt2a.jpg
│   ├── lab-3b-pt2b.jpg
│   ├── lab-3b-pt3.jpg
│   ├── lab-3b-pt4.jpg
│   ├── lab-3b-pt5.jpg
│   ├── lab-3b-pt6.jpg
│   ├── lab-3b-pt7.jpg
│   ├── lab-3b-pt8.jpg
│   ├── lab-3b-pt9.jpg
│   ├── terraform-apply.jpg
│   ├── terraform-destroy.jpg
│   ├── terraform-init-fmt-validate.jpg
│   └── terraform-plan.jpg
│
├── scripts/
│   ├── lab-3b.sh.tftpl
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
├── Jenkinsfile
├── README.md
├── STEPS.md
└── .gitignore
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

## 🏗️ Jenkinsfile CI/CD Pipeline

A Jenkins pipeline is included in the [**`Jenkinsfile`**](Jenkinsfile) for automating the Terraform deployment process. It performs the following stages:

1. **Checkout**: Retrieves the latest code from the Git repository.
2. **Terraform Init/Format/Validate**: Initializes Terraform, checks code formatting, and validates the configuration.
3. **Terraform Plan**: Generates an execution plan and archives it for review.
4. **Terraform Apply**: Applies the changes to the AWS environment if the plan stage is successful.
5. **Terraform Destroy**: Destroys the infrastructure, can be triggered manually or as part of a cleanup process.
6. **Post Actions**: Cleans up the workspace and logs the completion of the pipeline.

---

## 📦 Deliverables

The lab delivers the following artifacts:

| Deliverable                      | Lab | Screenshot                                                                   |
| ---------------------------------|-----| :---------------------------------------------------------------------------:|
| `lab-3b-pt1.jpg`                 | 3B  | ![lab-3b-pt1.jpg](/Screenshots/lab-3b-pt1.jpg)                               |
| `lab-3b-pt2a.jpg`                | 3B  | ![lab-3b-pt2a.jpg](/Screenshots/lab-3b-pt2a.jpg)                             |
| `lab-3b-pt2b.jpg`                | 3B  | ![lab-3b-pt2b.jpg](/Screenshots/lab-3b-pt2b.jpg)                             |
| `lab-3b-pt3.jpg`                 | 3B  | ![lab-3b-pt3.jpg](/Screenshots/lab-3b-pt3.jpg)                               |
| `lab-3b-pt4.jpg`                 | 3B  | ![lab-3b-pt4.jpg](/Screenshots/lab-3b-pt4.jpg)                               |
| `lab-3b-pt5.jpg`                 | 3B  | ![lab-3b-pt5.jpg](/Screenshots/lab-3b-pt5.jpg)                               |
| `lab-3b-pt6.jpg`                 | 3B  | ![lab-3b-pt6.jpg](/Screenshots/lab-3b-pt6.jpg)                               |
| `lab-3b-pt7.jpg`                 | 3B  | ![lab-3b-pt7.jpg](/Screenshots/lab-3b-pt7.jpg)                               |
| `lab-3b-pt8.jpg`                 | 3B  | ![lab-3b-pt8.jpg](/Screenshots/lab-3b-pt8.jpg)                               |
| `lab-3b-pt9.jpg`                 | 3B  | ![lab-3b-pt9.jpg](/Screenshots/lab-3b-pt9.jpg)                               |
| `STEPS.md`                       | 3B  | [STEPS.md](/STEPS.md)                                                        |
| `audit-pack/`                    | 3B  | [audit-pack/](/audit-pack/)                                                  |
| `deliverables/`                  | 3B  | [deliverables/](/deliverables/)                                              |
| `python/`                        | 3B  | [python/](/python/)                                                          |
| `s3-cloudfront-logs/`            | 3B  | [s3-cloudfront-logs/](/s3-cloudfront-logs/)                                  |

---

## 🧨 Terraform Teardown

To remove all deployed resources:

```bash
terraform destroy
```

![terraform-destroy](Screenshots/terraform-destroy.jpg)

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

* [AWS Transit Gateway Documentation](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html)
* [AWS Well-Architected Framework — Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
* [AWS Healthcare & HIPAA Compliance Whitepapers](https://aws.amazon.com/compliance/hipaa-compliance/)
* [Amazon RDS Security Best Practices](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SecurityBestPractices.html)
* [CloudFront Security & Origin Protection](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/security-overview.html)

---

## 👥 Authors

* **Author:** T.I.Q.S.
* **Group Leader:** John Sweeney

---
