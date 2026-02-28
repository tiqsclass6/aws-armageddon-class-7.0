variable "bgp_link_local" {
  description = "Lab 4A mandated link-local ranges and peer IPs (TWO tunnels only)"
  type = object({
    aws_tunnel1_inside_cidr = string
    aws_tunnel2_inside_cidr = string
    gcp_iface1_range        = string
    gcp_iface2_range        = string
    gcp_peer1_ip            = string
    gcp_peer2_ip            = string
  })
}

variable "gcp_bgp_asn" {
  description = "The BGP ASN to use for the Cloud Router"
  type        = number
  default     = 65001
}

variable "gcp_project_id" {
  description = "The ID of the GCP project"
  type        = string
  default     = "class-6-5-tiqs"
}

variable "gcp_region" {
  description = "The GCP region to deploy resources in"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "A zone in the region (for image family lookups or future zonal resources)"
  type        = string
  default     = "us-central1-a"
}

variable "name_prefix" {
  description = "Prefix for all resources created by this module"
  type        = string
  default     = "gcp-iowa"
}

variable "nihonmachi_subnet_cidr" {
  description = "The CIDR block for the Nihonmachi subnet"
  type        = string
  default     = "10.245.11.0/24"
}

variable "nihonmachi_proxy_subnet_cidr" {
  description = "The CIDR block for the Nihonmachi proxy subnet (required for INTERNAL_MANAGED ILB)"
  type        = string
  default     = "10.245.40.0/24"
}

variable "allowed_vpn_cidrs" {
  description = "Allow-list CIDRs that may access the internal app over HTTPS (VPN/TGW corridor only)"
  type        = list(string)
  default     = ["10.240.0.0/16"]
}

variable "aws_vpc_cidr" {
  description = "AWS Tokyo VPC CIDR (used for egress allow list + corridor assumptions)"
  type        = string
  default     = "10.240.0.0/16"
}

# -------------------------
# Compute-only branch app
# -------------------------
variable "machine_type" {
  description = "Machine type for the MIG instances"
  type        = string
  default     = "e2-medium"
}

variable "mig_size" {
  description = "Target size for the managed instance group"
  type        = number
  default     = 2
}

variable "enable_nat" {
  description = "Enable Cloud NAT for private instances to install packages without public IPs"
  type        = bool
  default     = true
}

variable "enable_gcp_vpn" {
  description = "Phase 2 toggle: create external VPN gateway, tunnels, BGP peers, and NCC spoke after AWS tunnel outside IPs exist"
  type        = bool
  default     = true
}

variable "enable_autoscaling" {
  description = "Enable autoscaling for the regional MIG"
  type        = bool
  default     = true
}

variable "autoscaler_min_replicas" {
  description = "Minimum number of MIG instances"
  type        = number
  default     = 2
}

variable "autoscaler_max_replicas" {
  description = "Maximum number of MIG instances"
  type        = number
  default     = 4
}

variable "autoscaler_cpu_target" {
  description = "Target CPU utilization for autoscaling (0.0 - 1.0)"
  type        = number
  default     = 0.80
}

variable "autoscaler_cooldown_sec" {
  description = "Cooldown period between scaling events"
  type        = number
  default     = 60
}

# -------------------------
# Tokyo RDS parameters (students wire these)
# -------------------------
variable "tokyo_rds_host" {
  description = "Tokyo RDS endpoint hostname"
  type        = string
  default     = "lab-4-tokyo-rds.cneq6k6qa400.ap-northeast-1.rds.amazonaws.com"
}

variable "tokyo_rds_port" {
  description = "Tokyo RDS port"
  type        = number
  default     = 3306
}

variable "tokyo_rds_user" {
  description = "Tokyo RDS user"
  type        = string
  default     = "admin"
}

variable "db_password_secret_name" {
  description = "GCP Secret Manager secret name containing the DB password"
  type        = string
  default     = "nihonmachi-tokyo-rds-password"
}

variable "aws_bgp_asn" {
  description = "AWS BGP ASN (TGW side)"
  type        = number
  default     = 64512
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

variable "aws_vpn_tunnel1_outside_ip" {
  description = "AWS tunnel 1 outside/public IP"
  type        = string
}

variable "aws_vpn_tunnel2_outside_ip" {
  description = "AWS tunnel 2 outside/public IP"
  type        = string
}