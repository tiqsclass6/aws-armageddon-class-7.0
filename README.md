# ☁️ **Class 7 Armageddon — Labs 1–4 + Bonus Tracks**

![AWS](https://img.shields.io/badge/AWS-Cloud-orange?style=for-the-badge&logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/Terraform-%E2%89%A51.9-844FBA?style=for-the-badge&logo=terraform&logoColor=white)
![CloudFront](https://img.shields.io/badge/CloudFront-Edge_Security-yellow?style=for-the-badge&logo=amazon-aws)
![WAFv2](https://img.shields.io/badge/AWS_WAFv2-Real_Time_Logging-red?style=for-the-badge&logo=amazonaws)
![Bedrock](https://img.shields.io/badge/Amazon_Bedrock-Auto_IR-black?style=for-the-badge&logo=amazon-aws)
![Multi_Region](https://img.shields.io/badge/Multi_Region-Transit_Gateway-blue?style=for-the-badge)
![Compliance](https://img.shields.io/badge/Compliance-HIPAA_Inspired-purple?style=for-the-badge)
![Observability](https://img.shields.io/badge/Observability-CloudWatch_&_Bedrock-green?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Production_Grade-success?style=for-the-badge)

---

## 📑 **Table of Contents**

- [**Project Overview**](#-project-overview)
- [**Project Requirements (All Labs)**](#-project-requirements-all-labs)
  - [**Common Requirements**](#common-requirements)
  - [**Lab-Specific Requirements**](#lab-specific-requirements)
- [**Resources Needed (All Labs)**](#-resources-needed-all-labs)
- [**Software & Tooling**](#️-software--tooling)
- [**Project Workflow**](#-project-workflow)
- [**Terraform Deployment (General Instructions)**](#-terraform-deployment-general-instructions)
- [**Lab Breakdown**](#-lab-breakdown)
  - [**Lab 1 — Secure Two-Tier Application Foundation**](#-lab-1--secure-two-tier-application-foundation)
  - [**Lab 2 — CloudFront Edge Security & Caching Mastery**](#-lab-2--cloudfront-edge-security--caching-mastery)
  - [**Lab 3 — Multi-Region Healthcare Architecture**](#-lab-3--multi-region-healthcare-architecture)
  - [**Lab 4 — Japan Medical Multi-Cloud Reality in Regulated Healthcare (AWS-GCP VPN and TGWs)**](#-lab-4--japan-medical-multi-cloud-reality-in-regulated-healthcare-aws-gcp-vpn-and-tgws)
- [**Ways Ahead / Future Enhancements**](#-ways-ahead--future-enhancements)
- [**Why This Portfolio Stands Out**](#-why-this-portfolio-stands-out)
- [**References**](#-references)
- [**Repository Governance**](#️-repository-governance)
- [**Troubleshooting (Common Across Labs)**](#️-troubleshooting-common-across-labs)
- [**Authors**](#-authors)

---

## 📘 **Project Overview**

This repository contains a **comprehensive, production-oriented AWS Terraform portfolio** developed through four progressively advanced labs and their complete bonus tracks.

The portfolio demonstrates **enterprise-grade cloud engineering practices**, including:

- Secure application architecture and private networking
- Edge security, origin cloaking, caching correctness, and CDN discipline
- Deep observability, automated incident response, and MTTR reduction
- Compliance-aware multi-region architecture with strict data residency controls

All infrastructure is provisioned declaratively using **Terraform**, follows **least-privilege security principles**, includes **CLI-verifiable evidence**, and reflects **real-world operational maturity** in security, reliability, and observability.

---

## 📋 **Project Requirements (All Labs)**

### Common Requirements

- Active AWS account with permissions for:
  - **VPC, EC2, RDS, ALB, CloudFront, WAFv2, Route 53, ACM, Secrets Manager, SSM, CloudWatch, SNS, Lambda, Bedrock, Transit Gateway**
- Administrative IAM user/role  
  *(or least-privilege role tailored per lab)*
- AWS CLI configured locally for validation and troubleshooting
- Active GCP account with permissions for:
  - **VPC, Compute Engine, Cloud VPN, IAM** (for Lab 4)
- Domain name under your control (Route 53 + ACM validation)
- Python 3.x environment for Bedrock IR scripts
- Terraform CLI installed locally (≥ 1.10 recommended)

### Lab-Specific Requirements

- **Lab 1**: EC2, RDS, Secrets Manager, SSM, WAF, Bedrock access
- **Lab 2**: CloudFront + ALB integration, custom domains, short TTL testing
- **Lab 3**: Multi-region architecture, Transit Gateway permissions, compliance mindset
- **Lab 4**: Japan Medical Multi-Cloud Reality in Regulated Healthcare (AWS-GCP VPN and TGWs)

---

## 🧰 **Resources Needed (All Labs)**

- AWS account  
  *(Free Tier sufficient for most labs; costs apply for ALB, CloudFront, Bedrock, TGWs)*
- AWS Provider **≥ 5.x** (≥ 6.x recommended)
- Domain name with NS delegation capability (Route 53)
- GCP account (for Lab 4)
  *GCP Free Tier may cover basic VPN and compute resources, but verify limits*
- Google Project with billing enabled (for Lab 4)
- Random Provider (for generating secrets and random values)
- TLS Provider (for ACM certificates)
- Terraform **≥ 1.10** (latest stable recommended)

### Local Environment

- Terraform CLI
- AWS CLI (v2 recommended)
- GCP SDK (for Lab 4)
- Git
- Python 3.x (for Bedrock IR scripts)
- Text editor / IDE
- Visual Studio Code (optional, with Terraform extension for syntax highlighting and linting)

**Optional:** VS Code with HashiCorp Terraform extension

---

## 🛠️ **Software & Tooling**

- **Terraform** — Infrastructure as Code (primary provisioning tool)
- **AWS CLI** — Validation, troubleshooting, and operational checks
- **Python + Flask** — Application layer
- **Watchtower** — CloudWatch logging integration
- **AWS Console** — Visual verification and evidence capture
- **Git** — Version control and branching strategy
- **Markdown** — Documentation and evidence formatting
- **Amazon Bedrock** — LLM-powered incident analysis and reporting
- **CloudWatch Logs Insights** — Log analysis and query validation
- **GCP Console & CLI** — For Lab 4 multi-cloud connectivity validation
- **GCP VPN and Networking Tools** — For multi-cloud connectivity setup and troubleshooting

---

## 🔁 **Project Workflow**

The labs follow a deliberate progression from secure foundations to edge mastery to global compliance:

1. **Lab 1** — Secure two-tier architecture, observability, automated incident response
2. **Lab 2** — CDN correctness, origin cloaking, edge security discipline
3. **Lab 3** — Compliance-aware multi-region architecture using Transit Gateways
4. **Lab 4** — Multi-cloud reality with AWS-GCP VPN and Transit Gateway

> Each lab includes self-contained Terraform code, bootstrap scripts, screenshots, CLI verification steps, and operational runbooks where applicable.

---

## 🗂️ **Project Structure & Workflow**

The repository is organized to reflect a **progressive, enterprise-grade learning and delivery path**, moving from foundational AWS constructs to advanced edge security, automation, and compliance-aware multi-region design.

```plaintext
aws-armageddon-terraform/
├── lab-1a/                # Foundational EC2 → RDS integration (Secrets Manager, logging)
├── lab-1b-1c/             # Configuration management, monitoring, alerting, IR simulation
├── lab-1c-bonus-a/        # Private EC2 only (SSM Session Manager, VPC endpoints, no NAT)
├── lab-1c-bonus-b/        # Public ALB + private EC2, HTTPS, WAF, CloudWatch monitoring
├── lab-1c-bonus-c/        # Apex domain support (ACM + Route 53) with HTTPS-only ingress
├── lab-1c-bonus-d/        # ALB access logging to encrypted S3 (enterprise observability)
├── lab-1c-bonus-e/        # WAFv2 logging to CloudWatch Logs (real-time visibility)
├── lab-1c-bonus-f/        # CloudWatch Logs Insights incident response & correlation pack
├── lab-1c-bonus-g/        # Automated IR pipeline (CloudWatch → Lambda → Bedrock v1)
├── lab-1c-bonus-h/        # Final MTTR automation with guardrailed Bedrock reporting
├── lab-1c-bonus-i/        # Amazon Bedrock–Assisted Incident Response Runbook
│
├── lab-2a/                # CloudFront origin cloaking with WAF + ALB (edge-only ingress)
├── lab-2b/                # Origin-driven caching correctness (static vs dynamic paths)
├── lab-2b-bam-a/          # Germany cloak variant (reinforced origin protection)
├── lab-2b-bam-b/          # Controlled cache invalidation (break-glass discipline)
├── lab-2b-bam-c/          # Conditional revalidation & RefreshHit proof (Lab 2 final)
│
├── lab-3a/                # Cross-region base architecture (Shinjuku ↔ Liberdade)
├── lab-3b/                # Healthcare-grade multi-region design (PHI isolation)
|
├── lab-4/                 # AWS-GCP VPN + Transit Gateway multi-cloud reality
|
└── README.md              # Primary portfolio documentation
```

---

## 🚀 **Terraform Deployment (General Instructions)**

```bash
# Navigate to the desired lab folder
cd lab-1c   # example

# Initialize, format, validate
terraform init
terraform fmt -recursive
terraform validate

# Review planned changes carefully
terraform plan

# Apply infrastructure
terraform apply

# Tear down resources when finished
terraform destroy
```

### Operational Notes

- CloudFront distributions require 10–20 minutes to deploy
- ACM certificate validation may require manual DNS confirmation
- Always review terraform plan output prior to apply

---

## 🧪 **Lab Breakdown**

### 🔐 **Lab 1 — Secure Two-Tier Application Foundation**

![lab1-diagram](/images/lab1-diagram.png)

1. [**Lab 1A - EC2 → RDS Integration**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-1a)  

   - **Task**: Establish secure EC2-to-RDS connectivity with dynamic credential management  
   - **Synopsis**: Deploys a basic but production-ready two-tier application using Secrets Manager for credentials and initial CloudWatch logging.  
   - **Key Artifacts**: `user_data.sh` (Flask + watchtower), Secrets Manager secret & IAM policy, `/init` and `/list` endpoints, CloudWatch log streams

2. [**Lab 1B-1C - Configuration Management & Incident Response**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-1b-1c)  

   - **Task**: Add configuration management, failure detection, alerting, and incident simulation  
   - **Synopsis**: Introduces SSM Parameter Store, CloudWatch metric filters/alarms, SNS notifications, and a full credential-drift incident response cycle.  
   - **Key Artifacts**: SSM parameters (`/lab/db/*`), CloudWatch alarm & metric filter, SNS topic/subscription, incident simulation screenshots & recovery proof

3. [**Lab 1C (Bonus A) - Private Compute & VPC Endpoints**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-1c-bonus-a)  

   - **Task**: Eliminate all public exposure of compute resources  
   - **Synopsis**: Moves EC2 to private subnet with SSM Session Manager access only, removes NAT Gateway, and uses **VPC** endpoints for AWS services.  
   - **Key Artifacts**: SSM, Logs, Secrets Manager interface endpoints, S3 Gateway Endpoint, SSM session proof screenshots

4. [**Lab 1C (Bonus B) - Secure Public Ingress with Private Compute**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-1c-bonus-b)  

   - **Task**: Introduce secure public ingress while keeping compute private  
   - **Synopsis**: Deploys an internet-facing ALB with HTTPS, integrates ACM TLS, associates WAF, and enables CloudWatch monitoring.  
   - **Key Artifacts**: ALB HTTPS listener, ACM certificate, WAF Web ACL, CloudWatch Dashboard, Route 53 records

5. [**Lab 1C (Bonus C) - Enterprise DNS-Integrated Ingress with Apex Support**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-1c-bonus-c)  

   - **Task**: Implement enterprise DNS-integrated ingress with apex support  
   - **Synopsis**: Enhances Bonus B with apex domain alias record in Route 53 and validated ACM certificate issuance.  
   - **Key Artifacts**: Route 53 apex alias A record, ACM certificate in ISSUED state, HTTPS-only listener, DNS resolution verification

6. [**Lab 1C (Bonus D) - Detailed Traffic Observability via ALB Logs**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-1c-bonus-d)  

   - **Task**: Enable detailed traffic observability via ALB logs  
   - **Synopsis**: Configures ALB access logging to encrypted S3 with secure bucket policy and CLI-verifiable delivery.  
   - **Key Artifacts**: ALB access log destination (S3), secure bucket policy (`aws:SecureTransport`), log delivery screenshots & CLI proof

7. [**Lab 1C (Bonus E) - Real-Time WAF Observability**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-1c-bonus-e)  

   - **Task**: Enable real-time WAF observability  
   - **Synopsis**: Sends WAFv2 logs to CloudWatch Logs using required naming convention for fast incident investigation.  
   - **Key Artifacts**: `aws_wafv2_web_acl_logging_configuration`, log group starting with `aws-waf-logs-`, CLI log validation (`filter-log-events`)

8. [**Lab 1C (Bonus F) - Production-Grade Incident Triage & Correlation Workflow**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-1c-bonus-f)  

   - **Task**: Build production-grade incident triage and correlation workflow  
   - **Synopsis**: Creates Logs Insights queries for WAF and application logs, plus a structured correlation runbook.  
   - **Key Artifacts**: A-series (WAF) & B-series (application) queries, correlation runbook screenshots, alarm recovery proof

9. [**Lab 1C (Bonus G) - Automated Incident Evidence Collection & Reporting**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-1c-bonus-g)  

   - **Task**: Automate incident evidence collection and reporting  
   - **Synopsis**: Implements CloudWatch alarm → **Lambda** → Logs Insights → Bedrock report generation → S3 storage → SNS notification pipeline.  
   - **Key Artifacts**: **Lambda** handler with Bedrock invocation, redacted JSON evidence, Markdown incident report, SNS notification proof

10. [**Lab 1C (Bonus H) - Automated Incident Reporting with Strong Guardrails**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-1c-bonus-h)  

    - **Task**: Finalize automated incident reporting with strong guardrails  
    - **Synopsis**: Refines Bedrock prompt engineering, enforces secret redaction, validates no-leak reports, and tests end-to-end pipeline.  
    - **Key Artifacts**: Guardrailed Bedrock template, **Lambda** test harness, verified Markdown & JSON deliverables, no-secrets validation

11. [**Lab 1C (Bonus I) - Amazon Bedrock–Assisted Incident Response Runbook**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-1c-bonus-i)  

    - **Task**: Develop an Amazon Bedrock–assisted incident response runbook  
    - **Synopsis**: Creates a structured runbook for leveraging Bedrock in incident response, including evidence collection, analysis, and remediation steps.  
    - **Key Artifacts**: Incident response runbook document, example incident scenario with Bedrock-assisted analysis, remediation playbook

---

### 🌐 **Lab 2 — CloudFront Edge Security & Caching Mastery**

![lab2-diagram](/images/lab2-diagram.png)

1. [**Lab 2A - Origin Hiding & Edge Protection**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-2a)  

   - **Task**: Completely hide the origin while enforcing edge protection  
   - **Synopsis**: Configures CloudFront as the sole public entry point with ALB unreachable directly via secret header and prefix list.  
   - **Key Artifacts**: `X-Lab2a-Origin-Secret` ALB rule, CloudFront prefix list SG rule, direct ALB access failure proof, WAF at CloudFront

2. [**Lab 2B - CDN Caching Behavior**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-2b)  

   - **Task**: Implement and prove correct CDN caching behavior  
   - **Synopsis**: Separates static (aggressive) and dynamic (no-cache) behaviors with managed policies and header validation.  
   - **Key Artifacts**: Managed cache & origin request policies, `Hit`, `Miss`, `Cache-Control` proof, HTTP header screenshots

3. [**Lab 2B (BAM Challenge A) - Honors**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-2b-bam-a)  

   - **Task**: Reinforce secure front-door pattern  
   - **Synopsis**: Strengthens origin protection with header gating, origin-driven caching, and IMDSv2 enforcement.  
   - **Key Artifacts**: Header-based ALB rule, cache policy disabled for dynamic paths, IMDSv2 proof, direct origin blocked

4. [**Lab 2B (BAM Challenge B) - Honors+**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-2b-bam-b)  

   - **Task**: Establish disciplined cache invalidation practice  
   - **Synopsis**: Prefers versioned assets, reserves invalidations for break-glass scenarios, minimizes blast radius and cost.  
   - **Key Artifacts**: Path-specific invalidation command, before/after cache header proof, break-glass runbook

5. [**Lab 2B (BAM Challenge C) - Honors++**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-2b-bam-c)  

   - **Task**: Demonstrate protocol-level caching correctness  
   - **Synopsis**: Proves conditional revalidation with `ETag`/`Last-Modified`, showing `RefreshHit` after TTL expiry.  
   - **Key Artifacts**: `Cache-Control: max-age=5, s-maxage=5`, validators present, timed `Miss → Hit → RefreshHit` sequence

---

### 🌍 **Lab 3 — Multi-Region Healthcare Architecture**

![lab3-diagram](/images/lab3-diagram.png)

1. [**Lab 3A - Cross‑Region Healthcare Architecture (Shinjuku ↔ Liberdade) Part I**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-3a)  

   - **Task**: Establish private cross-region connectivity with global ingress  
   - **Synopsis**: Deploys CloudFront front door, Transit Gateway peering, and initial residency controls across Shinjuku and Liberdade.  
   - **Key Artifacts**: Transit Gateway attachments & routes, cross-region SG rules, CloudFront global distribution, residency verification

2. [**Lab 3B - Cross‑Region Healthcare Architecture (Shinjuku ↔ Liberdade) Part II**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-3b)  

   - **Task**: Deliver compliance-aware multi-region architecture  
   - **Synopsis**: Enforces strict PHI residency in primary region, deploys stateless ASG in secondary region, includes full audit pack.  
   - **Key Artifacts**: Explicit PHI isolation, Transit Gateway routing, audit pack & Python scripts, end-to-end observability

---

### 🧬 **Lab 4 — Japan Medical Multi-Cloud Reality in Regulated Healthcare (AWS-GCP VPN and TGW's)**

![lab4-diagram (COMING SOON)](/images/lab4-diagram.png)

- [**🏥 Lab 4 — AWS ↔ GCP Secure Connectivity (IPSec VPN + BGP)**](https://github.com/tiqsclass6/aws-armageddon-class-7.0/tree/lab-4)  

---

## 🔮 **Ways Ahead / Future Enhancements**

- Implement CI/CD pipeline (GitHub Actions / Terraform Cloud) for automated deployments
- Containerize application layer (ECS Fargate / EKS)
- Introduce AWS FIS for chaos engineering and resilience testing
- Extend Bedrock IR pipeline with auto-remediation actions
- Add cross-account deployment using OIDC federation
- Publish internal runbooks and patterns derived from this work
- Explore additional multi-cloud patterns (Azure, Kubernetes, etc.)
- Continuously refine and expand the portfolio based on emerging best practices and feedback

---

## 🎯 **Why This Portfolio Stands Out**

### This work directly demonstrates competencies sought in **Senior → Staff** Cloud & DevOps positions, including

- Production-grade Infrastructure as Code discipline (modular Terraform, remote state, provider management)
- Secure-by-default architecture (private networking, SSM-only access, origin cloaking, least-privilege IAM)
- Advanced observability & SRE practices (Logs Insights, metric filters, alarms, Bedrock-powered auto-IR)
- Edge & CDN expertise (cache correctness, RefreshHit proofs, controlled invalidations)
- Compliance-aware design (PHI/data residency, HIPAA-inspired patterns, auditability)
- Incident response automation & MTTR reduction
- Multi-region operational maturity (Transit Gateway, private global connectivity)
- Multi-cloud reality (AWS-GCP VPN, cross-cloud connectivity)
- Real-world operational patterns (beyond academic exercises), including:
  - Secrets management with dynamic retrieval and rotation
  - Private compute with secure access patterns (SSM Session Manager, VPC endpoints)
  - Edge security with CloudFront + WAF and origin protection
  - Observability with CloudWatch Logs, metric filters, and Bedrock-assisted analysis
  - Compliance-aware multi-region architecture with strict data residency controls
  - Multi-cloud connectivity using AWS Transit Gateway and VPN to GCP

These are not academic exercises — they mirror real production patterns used by teams operating at scale in regulated and high-availability environments.

---

## 📚 **References**

- [**RFC 1918 - Address Allocation for Private Internets**](https://datatracker.ietf.org/doc/html/rfc1918)
- [**RFC 2401 - The Secure Shell (SSH) Protocol Architecture**](https://datatracker.ietf.org/doc/html/rfc2401)
- [**RFC 4271 - Border Gateway Protocol 4 (BGP)**](https://datatracker.ietf.org/doc/html/rfc4271)
- [**Well-Architected Framework**](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [**Security Best Practices**](https://aws.amazon.com/security/security-best-practices/)  
- [**HIPAA Compliance**](https://aws.amazon.com/compliance/hipaa-compliance/)  
- [**Amazon RDS Security Best Practices**](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_BestPractices.Security.html)  
- [**RDS Security Groups**](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Overview.RDSSecurityGroups.html)  
- [**Connecting to RDS**](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ConnectToInstance.html)  
- [**Secrets Manager**](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html)  
- [**Secrets Manager – Hardcoded Credentials**](https://docs.aws.amazon.com/secretsmanager/latest/userguide/hardcoded-db-creds.html)  
- [**EC2 User Guide**](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/concepts.html)  
- [**IAM Best Practices**](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)  
- [**Systems Manager Session Manager**](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)  
- [**VPC Interface Endpoints**](https://docs.aws.amazon.com/vpc/latest/privatelink/vpce-interface.html)  
- [**CloudWatch Metric Filters**](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html)  
- [**CloudWatch Alarms**](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/AlarmThatSendsEmail.html)  
- [**Amazon SNS**](https://docs.aws.amazon.com/sns/latest/dg/sns-create-subscribe-endpoint-to-topic.html)  
- [**Parameter Store**](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)  
- [**WAF Logging**](https://docs.aws.amazon.com/waf/latest/developerguide/logging.html)  
- [**WAF Logging to CloudWatch**](https://docs.aws.amazon.com/waf/latest/developerguide/logging-cw-logs.html)  
- [**WAF LoggingConfiguration API**](https://docs.aws.amazon.com/waf/latest/APIReference/API_LoggingConfiguration.html)  
- [**CloudWatch Logs Insights**](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/AnalyzingLogData.html)  
- [**Amazon Bedrock InvokeModel**](https://docs.aws.amazon.com/bedrock/latest/userguide/inference-invoke.html)  
- [**Bedrock Model Parameters**](https://docs.aws.amazon.com/bedrock/latest/userguide/model-parameters.html)  
- [**Lambda with SNS**](https://docs.aws.amazon.com/lambda/latest/dg/with-sns.html)  
- [**CloudFront Cache Key**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/understanding-the-cache-key.html)  
- [**Controlling Cache Key**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/controlling-the-cache-key.html)  
- [**Managed Cache Policies**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html)  
- [**Controlling Origin Requests**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/controlling-origin-requests.html)  
- [**CloudFront Security Overview**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/security-overview.html)  
- [**Restricting Access to Load Balancers**](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/restricting-access-to-load-balancer.html)  
- [**HTTP Conditional Requests (RFC 9110)**](https://www.rfc-editor.org/rfc/rfc9110.html#name-conditional-requests)  
- [**Transit Gateway Overview**](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html)  
- [**Transit Gateway Inter-Region Peering**](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-inter-region-peering.html)  
- [**RDS Security Best Practices**](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SecurityBestPractices.html)  
- [**Security Pillar**](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)  
- [**Terraform AWS Provider**](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)  
- [**Flask Documentation**](https://flask.palletsprojects.com/en/stable/)  
- [**Watchtower Library**](https://github.com/kislyuk/watchtower)  
- [**Terraform AWS Getting Started**](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)  
- [**Restricting ALB Access (Blog)**](https://aws.amazon.com/blogs/networking-and-content-delivery/restricting-access-to-application-load-balancers/)  
- [**Secrets Manager Best Practices (Blog)**](https://aws.amazon.com/blogs/security/how-to-use-aws-secrets-manager-securely-store-secrets-centralize-secret-management/)
- [**VPNs with Transit Gateway**](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-vpn.html)
- [**AWS-GCP VPN Reference Architecture**](https://docs.cloud.google.com/network-connectivity/docs/vpn/tutorials/create-ha-vpn-connections-google-cloud-aws)
- [**HIPAA Compliance on AWS**](https://aws.amazon.com/compliance/hipaa-compliance/)
- [**GCP VPN Documentation**](https://cloud.google.com/network-connectivity/docs/vpn)
- [**GCP Internal Load Balancing**](https://cloud.google.com/load-balancing/docs/internal)
- [**GCP IAM Best Practices**](https://cloud.google.com/blog/products/identity-security/iam-best-practice-guides-available-now)
- [**GCP Managed Instance Group (MIG) Documentation**](https://cloud.google.com/compute/docs/instance-groups)

---

## 🛡️ **Repository Governance**

This repository follows standard open-source and enterprise governance practices.  
See:

- [**CODE_OF_CONDUCT**](CODE_OF_CONDUCT.md) - expected behavior, reporting guidelines, and enforcement policies for community interactions
- [**CONTRIBUTING**](CONTRIBUTING.md) - guidelines for contributing to the project, including issue reporting, pull request process, and coding standards
- [**GOVERNANCE**](GOVERNANCE.md) - project decision-making structure, release management, and maintenance policies
- [**LICENSE**](LICENSE.txt) - open-source license governing the use, distribution, and modification of the codebase
- [**MAINTAINERS**](MAINTAINERS.md) - current maintainers, contribution guidelines, and code review process
- [**SECURITY**](SECURITY.md) - responsible disclosure guidelines and contact information for security issues
- [**SUPPORT**](SUPPORT.md) - contributions, issue reporting, and security disclosures are all welcome and will be handled according to the guidelines outlined in the respective documents.

---

## 🛠️ **Troubleshooting (Common Across Labs)**

- **`terraform init` fails** → Check Terraform version, provider constraints, AWS credentials, network connectivity
- **Secrets AccessDenied** → Verify IAM role attachment and secret ARN
- **RDS connection refused** → Confirm security group allows 3306 from EC2/ALB
- **SSM session fails** → Ensure **VPC** endpoints exist and instance has `AmazonSSMManagedInstanceCore`
- **CloudFront 504 / not deployed** → Wait 10–20 minutes; verify origin health & SG rules
- **WAF logs missing** → Log group must start with `aws-waf-logs-`; confirm logging config
- **Bedrock access denied** → Enable model access in Bedrock console (region-specific)
- **Alarm not triggering** → Validate metric filter pattern matches log message exactly
- **DNS not resolving** → Check Route 53 NS records match registrar; confirm ACM status is ISSUED
- **Transit Gateway connectivity issues** → Verify attachments, route tables, and SG rules in both regions
- **VPN tunnel down** → Check IPSec configuration, BGP status, and CloudWatch metrics for TGW VPN
- **GCP connectivity issues** → Validate GCP VPN configuration, firewall rules, and instance tags
- **General debugging** → Use AWS CLI for direct resource queries, check CloudWatch Logs, and review Terraform state for discrepancies
- **Cost concerns** → Monitor AWS Cost Explorer, tear down resources when not in use, and consider using AWS Free Tier where applicable

---

## 👤 **Authors**

- **Author:** T.I.Q.S.
- **Group Lead:** John Sweeney

> This portfolio is intentionally built to reflect **Staff-level engineering judgment** in security, observability, compliance, and operational excellence.
