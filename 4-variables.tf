variable "allowed_http_cidrs" {
  description = "CIDRs allowed to reach the Liberdade ALB on port 80 (CloudFront header still required)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "asg_min" {
  description = "ASG minimum capacity."
  type        = number
  default     = 3
}

variable "asg_desired" {
  description = "ASG desired capacity."
  type        = number
  default     = 6
}

variable "asg_max" {
  description = "ASG maximum capacity."
  type        = number
  default     = 9
}

variable "instance_type" {
  description = "EC2 instance type for Liberdade application instances."
  type        = string
  default     = "t3.micro"
}

variable "liberdade_region" {
  description = "Secondary region (Liberdade)."
  type        = string
  default     = "sa-east-1"
}

variable "origin_header_name" {
  description = "Custom header name for origin verification."
  type        = string
  default     = "x-origin-verify"
}

variable "origin_header_value" {
  description = "Custom header value for origin verification. Auto-generated if empty."
  type        = string
  default     = ""
  sensitive   = true
}

variable "origin_forward_header_name" {
  description = "Custom header name that the ALB adds when forwarding to the Liberdade application instances."
  type        = string
  default     = "x-forwarded-by"
}

variable "origin_forward_header_value" {
  description = "Custom header value that the ALB adds when forwarding to the Liberdade application instances."
  type        = string
  default     = "liberdade-alb"
}

variable "shinjuku_region" {
  description = "Primary region (Shinjuku)."
  type        = string
  default     = "ap-northeast-1"
}

variable "shinjuku_db_engine" {
  description = "RDS engine for Shinjuku."
  type        = string
  default     = "mysql"
}

variable "shinjuku_db_engine_version" {
  description = "RDS engine version for Shinjuku."
  type        = string
  default     = "8.4"
}

variable "shinjuku_db_instance_class" {
  description = "RDS instance class for Shinjuku."
  type        = string
  default     = "db.t3.micro"
}

variable "shinjuku_db_allocated_storage" {
  description = "RDS allocated storage (GiB)."
  type        = number
  default     = 20
}

variable "shinjuku_db_name" {
  description = "Initial database name."
  type        = string
  default     = "labdb"
}

variable "shinjuku_db_username" {
  description = "Master username."
  type        = string
  default     = "admin"
}

variable "shinjuku_private_route_table_name_prefix" {
  description = "Name prefix used to identify existing Shinjuku private route tables."
  type        = string
  default     = "shinjuku-private-rt"
}

variable "shinjuku_rds_sg_name" {
  description = "Name tag of the existing Shinjuku RDS Security Group."
  type        = string
  default     = "shinjuku-rds-sg"
}

variable "shinjuku_vpc_cidr" {
  description = "Existing Shinjuku VPC CIDR (used for discovery and routing)."
  type        = string
  default     = "10.240.0.0/16"
}