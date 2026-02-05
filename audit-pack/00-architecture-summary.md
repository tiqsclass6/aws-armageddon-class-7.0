# Lab 3A / 3B Architecture Summary  

## Audit-Ready Design – APPI Compliance Focus

## Overview

This architecture separates data storage from compute operations to comply with APPI data residency requirements. Personal Health Information (PHI) is stored exclusively in Japan (Tokyo region), while application compute occurs in São Paulo. All external access is routed through CloudFront, ensuring no direct exposure of the origin infrastructure.

## Regions and Data Residency

- **Primary region (storage)**: ap-northeast-1 (Tokyo)  
  - RDS MySQL instance: `shinjuku-rds`  
  - Stores all application data (notes database)  
  - No cross-region replication or read replicas  
- **Secondary region (compute only)**: sa-east-1 (São Paulo)  
  - No RDS instances present  
  - Application logic executes here via EC2 Auto Scaling Group  

**Proof**: Automated residency check confirms RDS exists only in ap-northeast-1 (see `01_data-residency-proof.txt` and `evidence.json`).

## Compute Layer

- EC2 Auto Scaling Group: `liberdade-asg` (sa-east-1)  
- Instances run a Flask application that queries the Tokyo RDS over Transit Gateway  
- Launch template includes IAM role for Secrets Manager access (RDS credentials) and SSM management  
- Health checks via ALB target group  

## Networking

- **VPCs**:
  - shinjuku-vpc: CIDR 10.240.0.0/16 (Tokyo)
  - liberdade-vpc: CIDR 10.245.0.0/16 (São Paulo)
- **Transit Gateway peering**:
  - `shinjuku_tgw` ↔ `liberdade_tgw`
  - Routes configured to direct traffic between VPC CIDRs via TGW attachments
  - No public internet routing for inter-region application traffic
- **Proof**: TGW attachments and routes captured in `05_network-corridor-proof.txt` and `evidence.json`.

## Edge Security and Access Control

- **CloudFront distribution**: `liberdade-cf` (global edge)  
  - Origin: Application Load Balancer (`liberdade-alb`) in sa-east-1  
  - Custom origin header (`x-origin-verify`) required for requests to reach ALB  
  - ALB listener rule forwards only requests with valid header; otherwise returns 403  
  - Viewer protocol: redirect-to-https  
  - Standard logging enabled to S3 bucket `lab-3b-cloudfront-logs` (prefix `lab-3b-cloudfront-logs/`)
- **Caching policy** (production): TTL = 0 (no caching) to ensure dynamic content freshness  
- **Temporary test policy** (for audit evidence): Positive TTL values applied briefly to demonstrate caching capability → 82.4% Hit rate observed in sampled logs  
- **Proof**: CloudFront log analysis shows traffic exclusively through edge and effective caching when enabled (see `02_edge-proof-cloudfront.txt`).

## Logging and Audit Trail

- **CloudTrail**: Management events recorded in both regions (90-day history available by default)  
- **CloudFront standard logs**: Delivered to S3 for access pattern and cache behavior analysis  
- **Other**: Application logs sent to CloudWatch Logs via Watchtower; no VPC Flow Logs configured in current deployment  
- **Retention**: S3 bucket versioning and lifecycle policies recommended (not enforced in current code)  

## Compliance Posture (APPI Alignment)

- PHI never stored or processed in sa-east-1 — only compute occurs there  
- Global accessibility achieved via CloudFront without global data storage  
- Origin protected by custom header + ALB rule → no public ALB endpoint exposure  
- All configuration changes auditable via CloudTrail  
- Design prioritizes provable controls over operational convenience, per regulated industry principle: "proof > operation"

**Note**: WAF is not currently attached to the CloudFront distribution. If required for future hardening, a web ACL can be associated via `web_acl_id`.
