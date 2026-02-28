# AWS Variables
variable "aws_azs" {
  description = "AWS Availability Zones"
  type        = list(string)

  default = [
    "ap-northeast-1a",
    "ap-northeast-1c"
  ]
}

variable "aws_bgp_asn" {
  description = "AWS BGP ASN"
  type        = number
  default     = 64512
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}

variable "aws_vpc_cidr" {
  description = "AWS VPC CIDR"
  type        = string
  default     = "10.240.0.0/16"
}

variable "aws_public_subnet_cidrs" {
  description = "AWS Public Subnet CIDRs"
  type        = list(string)

  default = [
    "10.240.1.0/24",
    "10.240.2.0/24"
  ]
}

variable "aws_private_subnet_cidrs" {
  description = "AWS Private Subnet CIDRs"
  type        = list(string)

  default = [
    "10.240.11.0/24",
    "10.240.12.0/24"
  ]
}

# GCP Variables
variable "enable_gcp_vpn" {
  description = "Phase 2: create GCP VPN tunnels/BGP peers/NCC spoke after AWS tunnel outside IPs exist"
  type        = bool
  default     = true
}

variable "gcp_bgp_asn" {
  description = "GCP BGP ASN"
  type        = number
  default     = 65501
}

variable "gcp_credentials_file" {
  description = "Optional path to a GCP service account JSON key file. Prefer GOOGLE_APPLICATION_CREDENTIALS env var."
  type        = string
  default     = ""
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
  default     = "class-6-5-tiqs"
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

# Other Variables
variable "allowed_vpn_cidrs" {
  description = "Allowed VPN CIDRs"
  type        = list(string)
  default     = ["10.240.0.0/16"]
}

variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "lab-4"
}

variable "nihonmachi_subnet_cidr" {
  description = "Nihonmachi Subnet CIDR"
  type        = string
  default     = "10.245.11.0/24"
}

variable "nihonmachi_proxy_subnet_cidr" {
  description = "Nihonmachi Proxy Subnet CIDR"
  type        = string
  default     = "10.245.40.0/24"
}

variable "tokyo_rds_password" {
  description = "Tokyo RDS master password (out-of-band). Do not hardcode."
  type        = string
  sensitive   = true
}

variable "db_password_secret_name" {
  description = "GCP Secret Manager secret name containing the DB password"
  type        = string
  default     = "nihonmachi-tokyo-rds-password"
}

variable "tunnel1_psk" {
  description = "Tunnel 1 PSK (out-of-band). Do not hardcode."
  type        = string
  sensitive   = true
}

variable "tunnel2_psk" {
  description = "Tunnel 2 PSK (out-of-band). Do not hardcode."
  type        = string
  sensitive   = true
}