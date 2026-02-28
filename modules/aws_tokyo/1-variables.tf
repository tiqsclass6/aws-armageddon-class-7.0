variable "name_prefix" {
  description = "Prefix for all resources created by this module"
  type        = string
  default     = "aws-tokyo"
}

variable "aws_vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.240.0.0/16"
}

variable "aws_azs" {
  description = "The availability zones to use for the subnets"
  type        = list(string)

  default = [
    "ap-northeast-1a",
    "ap-northeast-1c",
    "ap-northeast-1d"
  ]
}

variable "aws_public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)

  default = [
    "10.240.1.0/24",
    "10.240.2.0/24",
    "10.240.3.0/24"
  ]
}

variable "aws_private_subnet_cidrs" {
  description = "The CIDR blocks for the private subnets"
  type        = list(string)

  default = [
    "10.240.11.0/24",
    "10.240.12.0/24",
    "10.240.13.0/24"
  ]
}

variable "aws_bgp_asn" {
  description = "The BGP ASN to use for the TGW"
  type        = number
  default     = 64512
}

# Needed for AWS VPC routing to TGW toward the branch
variable "gcp_branch_cidr" {
  description = "GCP Iowa branch subnet CIDR that must be reachable over the VPN corridor"
  type        = string
}

# -------------------------
# Tokyo RDS (PHI lives here only)
# -------------------------
variable "enable_rds" {
  description = "Enable provisioning of Tokyo RDS (PHI region)"
  type        = bool
  default     = true
}

variable "rds_engine" {
  description = "RDS engine"
  type        = string
  default     = "mysql"
}

variable "rds_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "8.4.7"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_db_name" {
  description = "Initial database name"
  type        = string
  default     = "labdb"
}

variable "rds_username" {
  description = "Master username"
  type        = string
  default     = "admin"
}

variable "rds_password" {
  description = "Master password (out-of-band). Do not hardcode."
  type        = string
  sensitive   = true
}

variable "rds_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "rds_allowed_cidrs" {
  description = "CIDRs allowed to connect to RDS (corridor sources only). Use the AWS-side corridor CIDR(s)."
  type        = list(string)
  default     = []
}

variable "rds_multi_az" {
  description = "Multi-AZ for higher availability"
  type        = bool
  default     = false
}

variable "rds_backup_retention_days" {
  description = "Backup retention"
  type        = number
  default     = 7
}

variable "rds_deletion_protection" {
  description = "Prevent accidental deletion"
  type        = bool
  default     = false
}