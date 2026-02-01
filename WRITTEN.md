# Lab 3A — Japan Medical

## Cross-Region Architecture with AWS Transit Gateway (APPI-Compliant)

---

## Executive Summary

This lab demonstrates a legally compliant, enterprise-grade cross-region architecture for a medical application operating under Japan’s **Act on the Protection of Personal Information (APPI)**. The system provides **global access** to an application while enforcing **strict data residency**, ensuring that all Protected Health Information (PHI) is stored **only in Japan**.

The architecture uses:

* **Shinjuku (ap-northeast-1)** as the *data authority*
* **Liberdade (sa-east-1)** as *stateless compute*
* **AWS Transit Gateway (TGW)** to create a controlled, auditable data corridor
* **Amazon CloudFront** to deliver a single global URL without storing PHI

This design reflects how real healthcare platforms satisfy legal, security, and operational constraints simultaneously.

---

## Legal & Compliance Context (Why This Design Exists)

Japan’s APPI imposes strict requirements on the handling of personal and medical data. In practice, the safest and most common interpretation is:

> **Japanese patient medical data must be stored physically inside Japan.**

However, APPI does *not* prohibit global access. Doctors and staff may access systems from outside Japan, provided that:

* PHI is not stored outside Japan
* Data is protected in transit
* Access paths are auditable

This lab models that exact requirement.

**Key compliance principle:**

> **Access may be global. Storage must not be.**

---

## Regional Responsibilities

### Shinjuku — Primary Region (Data Authority)

Shinjuku is the source of truth and the only location where PHI exists at rest.

It contains:

* Amazon RDS (medical records database)
* Primary VPC
* Transit Gateway (hub)
* Secrets Manager (authoritative credentials)
* System Parameter Store
* Logging, monitoring, and auditing via CloudWatch and CloudTrail
* Read replicas

If Shinjuku becomes unavailable, the system may degrade, but **data residency is never violated**. This is intentional and correct.

---

### Liberdade — Secondary Region (Compute-Only)

Liberdade exists solely to serve users geographically closer to South America.

It contains:

* VPC
* EC2 Auto Scaling Group
* SSM Endpoint
* Application Load Balancer (ALB)
* CloudFront Distribution
* Application tier
* Transit Gateway (spoke)

It explicitly does **not** contain:

* RDS
* Read replicas
* Backups
* Persistent PHI storage

Liberdade is **stateless compute**. All reads and writes go directly to Shinjuku.

---

## Networking Model

### Why Transit Gateway

Transit Gateway is used instead of VPC peering because it provides:

* Centralized routing control
* Clear, auditable traffic paths
* Enterprise-grade segmentation
* A visible and reviewable “data corridor”

In regulated environments, **clarity beats convenience**.

---

### End-to-End Traffic Flow

Doctor (Liberdade)
→ CloudFront (global edge) → Liberdade EC2 (stateless) → Liberdade Transit Gateway → TGW Peering → Shinjuku Transit Gateway → Shinjuku VPC → Shinjuku RDS (PHI stored only here)

All traffic stays on the AWS backbone and is encrypted in transit.

---

## Single Global URL Design

The system exposes **one public URL**:

```plaintext
https://<cloudfront-domain>.com
```

CloudFront:

* Terminates TLS
* Applies WAF protections
* Routes users to the nearest healthy region
* Never stores PHI
* Respects cache-control headers

CloudFront is permitted because it is **not a database** and does not persist medical data.

---

## Terraform & DevOps Design

### Infrastructure as Code

All infrastructure is defined using Terraform, ensuring:

* Repeatability
* Auditability
* Clear separation of concerns

Key components:

* VPCs, subnets, NAT, and routing
* Transit Gateway and peering
* ALB, ASG, and CloudFront
* IAM roles for least-privilege access

---

### Bootstrapping & Operations

EC2 instances are provisioned using hardened user-data scripts that:

* Install required dependencies with retry logic
* Enable and validate SSM Session Manager
* Start the application via systemd
* Expose a `/health` endpoint for ALB checks

This ensures reliable bootstrapping in private subnets.

---

## Security Model

### Network Security

* No public database access
* RDS inbound allowed only from:

  * Shinjuku application CIDR
  * Liberdade VPC CIDR
* All cross-region traffic flows through TGW

### ALB Hardening

* ALB ingress restricted to **CloudFront-only** using AWS-managed prefix lists
* Optional origin-verification headers enforced at the listener layer

### Identity & Access

* EC2 instances use IAM roles (no static credentials)
* Secrets retrieved at runtime from Secrets Manager
* All access is logged and auditable

This is **compliance by design**, not by policy.

---

## Verification & Validation

### From a Liberdade EC2 instance (via SSM)

Network reachability test:

```bash
nc -vz <shinjuku-rds-endpoint> 3306
```

![lab-3a-pt2.jpg](/Screenshots/lab-3a-pt2.jpg)

Application verification:

* Submit a record from Liberdade
* Retrieve the same record via Shinjuku
* Confirm a single authoritative database

### From AWS Console / CLI

* TGW attachments exist in both regions
* TGW route tables contain cross-region CIDRs
* VPC route tables point traffic to local TGWs

---

## Explicit Non-Goals (What Is Not Allowed)

* RDS outside Shinjuku
* Cross-region replicas
* Aurora Global Database
* Local caching of PHI
* CloudFront caching patient records
* Active/active databases

Violating these rules makes the architecture **legally invalid**, not just technically incorrect.

---

## Why This Lab Matters

Most engineers learn:

* “Make it multi-region”
* “Replicate everything”

This lab teaches:

* How **law shapes architecture**
* How to design **asymmetric global systems**
* How to explain tradeoffs to security, legal, and auditors
* How real DevOps teams operate under regulation

---

## Interview Talk Track

> “I designed a cross-region medical system where all PHI remained in Japan to comply with APPI. Shinjuku hosted the database, Liberdade ran stateless compute, and Transit Gateway provided a controlled data corridor. CloudFront delivered a single global URL without violating data residency.”

That answer stops the room.

---

## Key Takeaways

* Global access does **not** require global storage
* Compute can move; regulated data cannot
* Transit Gateway creates a compliant data corridor
* CloudFront enables a single URL without storing PHI

---
