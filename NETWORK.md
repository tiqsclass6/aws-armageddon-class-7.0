# 🌐 **Lab 4 — Network Addressing & BGP Planning Document**

---

## 🔛 **One-Sentence Architecture Summary**

**All PHI resides in AWS Tokyo (10.240.0.0/16), while GCP Iowa (10.245.11.0/24) operates as a compute-only branch connected via dual IPSec tunnels with tightly controlled BGP route exchange.**

---

## 1️⃣ **Executive Summary**

This document defines all network address spaces, BGP configurations, link-local ranges, and routing advertisements used to establish secure IPSec VPN connectivity between:

* **AWS Tokyo (ap-northeast-1)** — Authoritative PHI region
* **GCP Iowa (us-central1)** — Compute-only branch

All routing is explicit, minimal, and compliant with data residency requirements.

---

## 2️⃣ **AWS Tokyo — Network Plan**

## Region 1

```text
ap-northeast-1
```

## VPC Configuration (PHI Region)

| **Resource**        | **Value**                          |
| ------------------- | ---------------------------------- |
| **VPC Name**        | **tokyo-vpc**                      |
| **CIDR Block**      | **10.240.0.0/16**                  |
| **Private Subnets** | **10.240.11.0/24, 10.240.12.0/24** |
| **Public Subnets**  | **(Optional, not used for PHI)**   |

---

## RDS (Private Only)

| **Resource**        | **Value**                      |
| ------------------- | ------------------------------ |
| **Engine**          | **MySQL**                      |
| **Version**         | **8.4.7**                      |
| **Placement**       | **Private Subnet**             |
| **Accessible From** | **GCP 10.245.11.0/24 via VPN** |
| **Public Access**   | ❌ **Disabled**                |

---

## Transit Gateway (TGW)

| **Parameter**         | **Value**     |
| --------------------- | ------------- |
| **Name**              | **lab-4-tgw** |
| **ASN**               | **64512**     |
| **Attachments**       | **VPC + VPN** |
| **Route Propagation** | **Enabled**   |

---

## 3️⃣ **GCP Iowa — Network Plan**

### Region 2

```text
us-central1
```

---

### VPC Configuration (Compute-Only Branch)

| **Resource**              | **Value**          |
| ------------------------- | ------------------ |
| **VPC Name**              | **nihonmachi-vpc** |
| **CIDR Block**            | **10.245.11.0/24** |
| **Subnet**                | **10.245.11.0/24** |
| **Private Google Access** | **Enabled**        |

---

### Internal Load Balancer (ILB)

| **Resource**       | **Value**             |
| ------------------ | --------------------- |
| **Type**           | **Internal HTTPS**    |
| **IP Range**       | **10.245.11.x**       |
| **Reachable From** | **VPN corridor only** |
| **Public Access**  | ❌ **Disabled**       |

---

### Managed Instance Group (MIG)

| **Resource**          | **Value**          |
| --------------------- | ------------------ |
| **VM Type**           | **e2-medium**      |
| **Instance Template** | **nihonmachi-tpl** |
| **DB Storage**        | ❌ **None**        |
| **RDS Access**        | **Via VPN only**   |

---

## 4️⃣ **IPSec VPN Configuration**

## Connectivity Type

```text
Site-to-Site IPSec VPN (HA)
Dynamic Routing (BGP)
Two tunnels for redundancy
```

---

## 5️⃣ **BGP Configuration**

## ASN Allocation

| **Side**             | **ASN**   |
| -------------------- | --------- |
| **AWS Tokyo (TGW)**  | **64512** |
| **GCP Cloud Router** | **65001** |

---

## Link-Local BGP Ranges (Required)

These ranges are used **only inside the tunnel**.

### Tunnel 1

| **Parameter**     | **Value**           |
| ----------------- | ------------------- |
| **CIDR**          | **169.254.12.0/30** |
| **AWS Peer IP**   | **169.254.12.1**    |
| **GCP Interface** | **169.254.12.2**    |

---

### Tunnel 2

| **Parameter**     | **Value**           |
| ----------------- | ------------------- |
| **CIDR**          | **169.254.12.4/30** |
| **AWS Peer IP**   | **169.254.12.5**    |
| **GCP Interface** | **169.254.12.6**    |

---

## 6️⃣ **CIDR Advertisement Policy (Strict)**

## AWS → GCP Advertises

```text
10.240.0.0/16
```

### So What?

* Authoritative Tokyo PHI region
* Allows branch compute to reach RDS
* No over-advertisement

---

## GCP → AWS Advertises

```text
10.245.11.0/24
```

### Why?

* Branch compute subnet only
* No additional networks exposed

---

## 7️⃣ **Route Validation Matrix**

| **Source**   | **Destination** | **Expected** | **Allowed?**  |
| ------------ | --------------- | ------------ | ------------- |
| **GCP VM**   | **10.240.x.x**  | **VPN**      | ✅ **Yes**    |
| **AWS RDS**  | **10.245.11.x** | **VPN**      | ✅ **Yes**    |
| **Internet** | **10.245.11.x** | **Direct**   | ❌ **No**     |
| **Internet** | **10.240.x.x**  | **Direct**   | ❌ **No**     |

---

## 8️⃣ **Security Enforcement**

| **Control**           | **Implementation**  |
| --------------------- | ------------------- |
| **Encryption**        | **IPSec (AES-256)** |
| **Key Exchange**      | **PSK per tunnel**  |
| **Redundancy**        | **Dual tunnels**    |
| **Routing**           | **BGP only**        |
| **Public Exposure**   | **None**            |
| **PHI Outside Japan** | ❌ **Prohibited**   |

---

## 9️⃣ **Compliance Alignment**

* No databases in GCP
* No PHI logging in GCP
* No disk persistence of PHI
* Explicit CIDR advertisement control
* VPN keys handled out-of-band
* Audit artifacts preserved

---

## 🔟 **Traffic Flow Summary**

```text
GCP VM (10.245.11.x)
        ↓
Cloud Router (ASN 65001)
        ↓
HA VPN Gateway
        ↓
IPSec Tunnel (169.254.12.x)
        ↓
AWS Transit Gateway (ASN 64512)
        ↓
Tokyo VPC (10.240.0.0/16)
        ↓
RDS (Private Subnet - 10.240.11.x/24)
```

---

## 1️⃣1️⃣ **Failure Domains**

| **Failure**            | **Impact**                      |
| ---------------------- | ------------------------------- |
| **Single tunnel down** | **No outage (BGP failover)**    |
| **GCP VM restart**     | **No PHI persistence**          |
| **TGW outage**         | **Cross-cloud traffic stops**   |
| **PSK compromise**     | **Immediate rotation required** |

---
