data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com"
}

data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs"
  type        = string
  default     = "alb-logs"
}

variable "app_subdomain" {
  description = "Subdomain for the application"
  type        = string
  default     = "app"
}

variable "aws_sns_topic_subscription_email_alert_endpoint" {
  description = "Email endpoint for SNS topic subscription"
  type        = string
  default     = "bjett2000@hotmail.com"
}

variable "create_app_record" {
  type        = bool
  description = "Also create app.<domain> Alias A -> ALB"
  default     = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "domain_name" {
  description = "Root domain name for Route 53 and ACM"
  type        = string
  default     = "theinternationalquietstorm.com"
}

variable "enable_waf" {
  description = "Enable AWS WAF on the ALB"
  type        = bool
  default     = true
}

variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "lab-1c"
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "waf_log_retention_days" {
  description = "Retention period (days) for WAF CloudWatch logs"
  type        = number
  default     = 7
}