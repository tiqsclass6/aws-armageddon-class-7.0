# 🏥 **Lab 4 — Japan Medical (AWS ↔ GCP Secure Connectivity (IPSec VPN + BGP))**

![AWS](https://img.shields.io/badge/AWS-ap--northeast--1-orange?logo=amazonaws)
![GCP](https://img.shields.io/badge/GCP-us--central1-blue?logo=googlecloud)
![IPSec VPN](https://img.shields.io/badge/IPSec-VPN-green)
![BGP](https://img.shields.io/badge/Routing-BGP-critical)
![Private IPs](https://img.shields.io/badge/Private%20IP-Only-yellow)
![Compliance](https://img.shields.io/badge/Compliance-Japan%20PHI-important)
![Data Residency](https://img.shields.io/badge/Data%20Residency-Japan-red)
![Secrets Management](https://img.shields.io/badge/Secrets-Management-informational)
![Multi-Cloud](https://img.shields.io/badge/Multi--Cloud-Architecture-blueviolet)
![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)
![Status](https://img.shields.io/badge/Lab-Completed-success)

---

## 🎓 **Career Takeaway**

> Many engineers can configure VPNs.
> Few can do it safely, compliantly, and defensibly.

This lab demonstrates:

- Multi-cloud coordination
- BGP routing discipline
- Secrets handling maturity
- Regulated environment design

Planning Documentation is located in the [**NETWORK.md**](NETWORK.md) file.

---

## 🗣️ **Interview Talk Track**

> “We connected a GCP-based medical branch to AWS using IPSec VPN and BGP, while ensuring all PHI remained in Japan. The GCP side ran compute only, and routing was tightly controlled to meet compliance requirements.”

---

## 🎯 **Lab Objective**

Design and validate secure, compliant multi-cloud connectivity between:

- **AWS Tokyo (ap-northeast-1)** → Authoritative PHI Region  
- **GCP Iowa (us-central1)** → Compute-only branch  

**Using:**

- IPSec Site-to-Site VPN  
- BGP for dynamic routing  
- Private IP routing only  
- Strict compliance boundaries  
- No PHI storage outside Japan  

This lab simulates real-world regulated multi-cloud architecture.

---

## 🧠 **Why This Lab Exists**

Real enterprises operate under:

- Legal constraints
- Data localization laws
- Multi-cloud environments
- Separate infrastructure teams
- Compliance audits

This lab emphasizes **discipline, routing control, and secrets management** over “just making it work.”

> Secure connectivity is as much about process as it is about packets.

---

## 🌍 **Architecture Overview**

### **Regions**

| **Provider** | **Region**             | **Role**                     |
|--------------|------------------------|------------------------------|
| **AWS**      | **ap-northeast-1**     | **PHI authoritative region** |
| **GCP**      | **us-central1**        | **Compute-only branch**      |

---

## 🏗️ **Lab Requirements**

### 🔐 **Security Constraints (Non-Negotiable)**

- ❌ No PHI stored in GCP
- ❌ No databases in GCP
- ❌ No disk persistence of medical data
- ❌ No PHI logging
- ✅ Encrypted IPSec VPN tunnels
- ✅ Explicit BGP route control
- ✅ Out-of-band PSK handling
- ✅ Secrets not committed to Git

> [!WARNING]
> If it works but violates these — it fails.

---

## 🧩 **Project Structure**

```text
LAB-4/
├── full-audit-2026/
│   ├── ny/
│   │   ├── gcp_evidence.json
│   │   ├── gcp_firewall_rules.txt
│   │   ├── gcp_forwarding_rules.txt
│   │   └── gcp_vpn_tunnels.txt
│   │
│   └── tokyo/
│       ├── aws_evidence.json
│       ├── aws_routes.txt
│       ├── aws_vpn_connections.txt
│       └── cloudtrail_recent_full.json
│
├── modules/
│   ├── aws_tokyo/
│   │   ├── 1-variables.tf
│   │   ├── 2-main.tf
│   │   └── 3-outputs.tf
│   │
│   ├── gcp_iowa/
│   │   ├── 1-variables.tf
│   │   ├── 2-network.tf
│   │   ├── 3-nat.tf
│   │   ├── 4-firewall.tf
│   │   ├── 5-compute.tf
│   │   ├── 6-ilb.tf
│   │   ├── 7-vpn.tf
│   │   ├── 8-iam.tf
│   │   ├── 9-outputs.tf
│   │   └── startup.sh.tftpl
│   │
│   ├── vpn/
│       ├── 1-variables.tf
│       ├── 2-main.tf
│       └── 3-outputs.tf
│
├── python/
│   └── malgus_collect_evidence.py
│
├── Screenshots/
│   ├── lab4-aws-tgw.jpg
│   ├── lab4-aws-vpn.jpg
│   ├── lab4-deliverable-pt1.jpg
│   ├── lab4-deliverable-pt2.jpg
│   ├── lab4-deliverable-pt3.jpg
│   ├── lab4-deliverable-pt4.jpg
│   ├── lab4-deliverable-pt5.jpg
│   ├── lab4-gcloud-compute-routers-pt1.jpg
│   ├── lab4-gcloud-compute-routers-pt2.jpg
│   ├── lab4-gcp-ilb.jpg
│   ├── lab4-gcp-mig.jpg
│   ├── lab4-gcp-vpn.jpg
│   ├── lab4-malgus-collect-evidence.jpg
|   ├── lab4-rds-pt1.jpg
|   ├── lab4-rds-pt2.jpg
│   ├── terraform-apply.jpg
│   ├── terraform-destroy.jpg
│   ├── terraform-init-fmt-validate.jpg
│   └── terraform-plan.jpg
│
├── .gitattributes
├── .gitignore
├── 0-versions.tf
├── 1-providers.tf
├── 2-variables.tf
├── 3-locals.tf
├── 4-main.tf
├── 5-outputs.tf
├── README.md
└── STEPS.md
```

---

## 💼 **Why This Layout Works for Portfolio**

- Clearly separates AWS and GCP responsibilities
- Demonstrates BGP establishment proof
- Shows routing discipline
- Shows internal-only access design
- Shows compute-only GCP implementation
- Includes automation evidence (Python script)

---

## 🚀 **Terraform Deployment Steps**

### 1️⃣ **Initialize, Format, & Validate**

```bash
terraform init
terraform fmt -recursive
terraform validate
```

  ![terraform-init-fmt-validate.jpg](/Screenshots/terraform-init-fmt-validate.jpg)

### 2️⃣ **Plan**

```bash
terraform plan
```

  ![terraform-plan.jpg](/Screenshots/terraform-plan.jpg)

### 3️⃣ **Apply**

```bash
terraform apply
```

  ![terraform-apply.jpg](/Screenshots/terraform-apply.jpg)

---

## 📸 **Infrastructure Build Evidence**

### 🔄 **AWS Side — Tokyo (ap-northeast-1)**

| Deliverable | Description                          | Screenshot                                          |
| ----------- | ------------------------------------ | ----------------------------------------------------|
| 1           | Transit Gateway Created              | ![lab4-aws-tgw.jpg](/Screenshots/lab4-aws-tgw.jpg)  |
| 2           | RDS Database Configuration (Part I)  | ![lab4-rds-pt1.jpg](/Screenshots/lab4-rds-pt1.jpg)  |
| 3           | RDS Database Configuration (Part II) | ![lab4-rds-pt2.jpg](/Screenshots/lab4-rds-pt2.jpg)  |

---

### 🔄 **GCP Side — Iowa (us-central1)**

| Deliverable | Description                          | Screenshot                                                                               |
| ----------- | ------------------------------------ | ---------------------------------------------------------------------------------------- |
| 1           | Internal HTTPS Load Balancer         | ![lab4-gcp-ilb.jpg](/Screenshots/lab4-gcp-ilb.jpg)                                       |
| 2           | Managed Instance Group (MIG)         | ![lab4-gcp-mig.jpg](/Screenshots/lab4-gcp-mig.jpg)                                       |

---

## 📦 **Artifacts & Deliverables**

### 📦 **Deliverable 1 — Connectivity Evidence**

#### **GCP Side**

```bash
gcloud compute routers get-status nihonmachi-router --region us-central1
```

![lab4-gcloud-compute-routers-pt1.jpg](/Screenshots/lab4-gcloud-compute-routers-pt1.jpg)
![lab4-gcloud-compute-routers-pt2.jpg](/Screenshots/lab4-gcloud-compute-routers-pt2.jpg)

**Evidence:**

![lab4-gcp-vpn.jpg](/Screenshots/lab4-gcp-vpn.jpg)

- BGP session `Established`
- Correct CIDRs learned

#### **AWS Side**

**Show:**

![lab4-aws-vpn.jpg](/Screenshots/lab4-aws-vpn.jpg)  |

- TGW route table entries
- BGP peer status
- Only 10.240.0.0/16 and 10.245.11.0/24 exchanged

---

### 📦 **Deliverable 2 — Network Diagram**

![diagram.png](/Screenshots/diagram.png)

---

### 📦 **Deliverable 3 — Private-Only Access Proof (GCP ILB)**

```bash
gcloud compute forwarding-rules describe lab-4-fr --region us-central1
```

![lab4-deliverable-pt1.jpg](/Screenshots/lab4-deliverable-pt1.jpg)

**From inside VPN corridor (SSH into VM):**

```bash
curl -k https://<INTERNAL_LB_IP>/health
curl -k https://<INTERNAL_LB_IP>/
```

![lab4-deliverable-pt2.jpg](/Screenshots/lab4-deliverable-pt2.jpg)

**From Public Internet (outside VPN corridor):**

```bash
curl -k https://<INTERNAL_LB_IP>/health
curl -k https://<INTERNAL_LB_IP>/
```

![lab4-deliverable-pt3.jpg](/Screenshots/lab4-deliverable-pt3.jpg)

**Expected:**

- Works internally
- Fails externally

---

### 📦 **Deliverable 4 — MIG Proof**

**From Terminal or Git Bash:**

```bash
gcloud compute instance-groups managed list --regions us-central1
gcloud compute instances list --filter="name~nihonmachi-app"
```

![lab4-deliverable-pt4.jpg](/Screenshots/lab4-deliverable-pt4.jpg)

**Include:**

- MIG exists
- Multiple instances running

---

### 📦 **Deliverable 5 — Tokyo RDS Connectivity Proof**

**From inside VPN corridor (SSH into VM):**

```bash
python3 /usr/local/bin/rds_test.py
```

![lab4-deliverable-pt5.jpg](/Screenshots/lab4-deliverable-pt5.jpg)

> [!NOTE]
> I did not include command `source /etc/profile.d/tokyo_rds.sh` because it resets the PATH and causes the Python script to fail. The necessary environment variables were exported manually in the terminal session for testing purposes. In a production scenario, the startup script would handle this automatically on instance boot.

---

### 📦 **Deliverable 6 — Malgus Python**

```bash
chmod +x python/malgus_collect_evidence.py
python python/malgus_collect_evidence.py
```

![lab4-malgus-collect-evidence.jpg](/Screenshots/lab4-malgus-collect-evidence.jpg)

- [**Malgus Python Script**](python/malgus_collect_evidence.py)
- [**Full Audit Folder**](full-audit-2026/)

---

### 📦 **Deliverable 7 — Process Write-Up (PSK Discipline)**

#### Pre-shared keys (PSKs)

- Pre-shared keys were generated using a high-entropy password generator. Each tunnel used a unique PSK to isolate failure domains and allow independent rotation. The PSKs were never stored in Terraform code, committed to Git, or shared over chat. Instead, they were stored temporarily in a secure password manager and shared out-of-band as a one-time secret. Terraform consumed PSKs via a local secrets.auto.tfvars file excluded from version control. In regulated environments, VPN credentials represent direct encrypted access into sensitive networks. Any leakage creates an unauthorized access path. Proper PSK handling demonstrates audit readiness and operational maturity.

---

### 📦 **Deliverable 8 — Compliance Statement**

- The architecture adheres to Japanese data residency and protection requirements by ensuring that all protected health information (PHI) remains stored exclusively within the AWS Tokyo region, which serves as the authoritative location for regulated data. No persistent storage or databases are deployed in the GCP Iowa environment, rendering it compute-only and thereby preventing any PHI from being housed outside Japan. Access to the Tokyo-based RDS instance occurs solely through encrypted IPSec VPN tunnels established between the AWS Transit Gateway and the GCP HA VPN gateway. These tunnels utilize BGP to dynamically exchange only explicitly approved CIDR ranges, thereby enforcing strict network-level controls and preventing unauthorized data exposure.

- This multi-cloud design effectively segregates compute operations in GCP from storage responsibilities in AWS, without expanding the PHI storage footprint beyond Japanese jurisdiction. The configuration aligns with the principles of the Act on the Protection of Personal Information (APPI), Japan's primary data protection framework, which does not impose strict data localization mandates for personal data, including sensitive categories such as health information. Instead, the APPI focuses on appropriate safeguards for cross-border transfers, consent mechanisms, and security measures when personal data leaves Japan. By maintaining all PHI within Japan and restricting external access to encrypted, controlled channels, the architecture satisfies relevant compliance expectations for data handling in regulated environments.
  
- 🔎 **References:**
  
  - [*Japanese Law Protection of Personal Information (APPI)*](https://www.ppc.go.jp/en/legal/)
  - [*Japanese Law Translation - APPI*](https://www.japaneselawtranslation.go.jp/en/laws/view/4241/en)

---

## 🧹 **Tear Down Steps**

### **Terraform Destroy**

```bash
terraform destroy
```

  ![terraform-destroy.jpg](/Screenshots/terraform-destroy.jpg)

---

## 🧠 **References**

### 📚 **AWS References**

- [**RFC 1918 - Private Addressing**](https://datatracker.ietf.org/doc/html/rfc1918)
- [**RFC 4271 - BGP**](https://datatracker.ietf.org/doc/html/rfc4271)
- [**AWS Transit Gateway Documentation**](https://docs.aws.amazon.com/vpc/latest/tgw/)
- [**AWS Site-to-Site VPN Documentation**](https://docs.aws.amazon.com/vpn/latest/s2svpn/)
- [**AWS Transit Gateway Overview**](https://docs.aws.amazon.com/vpc/latest/tgw/what-is-transit-gateway.html)

### 📚 **GCP References**

- [**RFC 1918 - Private Addressing**](https://datatracker.ietf.org/doc/html/rfc1918)
- [**RFC 2401 - IPSec**](https://datatracker.ietf.org/doc/html/rfc2401)
- [**GCP VPN Documentation**](https://cloud.google.com/network-connectivity/docs/vpn)
- [**GCP Cloud Router Documentation**](https://cloud.google.com/network-connectivity/docs/router)
- [**GCP Internal Load Balancing Documentation**](https://cloud.google.com/load-balancing/docs/l7-internal)

---

## 🧯 **Troubleshooting Guide**

### ❌ **BGP Not Established**

- Verify ASN matches
- Verify inside tunnel IPs
- Verify PSKs match
- Confirm firewall rules

### ❌ **Routes Not Learned**

- Check Cloud Router advertisement mode
- Confirm TGW route propagation
- Verify CIDR correctness

### ❌ **Internal LB Not Reachable**

- Confirm firewall rules
- Confirm health checks passing
- Confirm instance listening on 443
- Confirm ILB IP is internal

### ❌ **RDS Connection Fails**

- Confirm AWS Security Group allows GCP CIDR
- Confirm route tables
- Confirm correct DB endpoint

---

## 🧠 **Final Reminder**

> [!NOTE]
>> Secure connectivity is not about speed.
>> It is about control, discipline, and defensibility.

---

## 👥 **Authors**

- **Author:** T.I.Q.S.
- **Group Leader:** John Sweeney
