data "aws_acm_certificate" "tiqs_existing_wildcard" {
  domain      = "*.theinternationalquietstorm.com"
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com"
}

variable "alb_access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
  type        = string
  default     = "alb-access-logs"
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

variable "bonus_h_bedrock_model_id_primary" {
  description = "Primary Bedrock model id for Bonus G (Claude). Requires model access approval in the account/region."
  type        = string
  default     = "anthropic.claude-3-5-sonnet-20240620-v1:0"
}

variable "bonus_h_bedrock_model_id_fallback" {
  description = "Fallback Bedrock model id for Bonus G (use a model that is enabled and not EOL)."
  type        = string
  default     = "us.amazon.nova-lite-v1:0"
}

variable "bonus_h_reports_bucket_name" {
  description = "Optional custom S3 bucket name for IR reports (blank = auto)."
  type        = string
  default     = ""
}

variable "bonus_h_reports_prefix" {
  description = "S3 prefix for report objects."
  type        = string
  default     = "reports"
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
  description = "Domain name for Route 53 and ACM"
  type        = string
  default     = "theinternationalquietstorm.com"
}

variable "enable_bonus_h_bedrock_auto_ir" {
  description = "Enable Bonus G Bedrock auto incident report pipeline."
  type        = bool
  default     = true
}

variable "enable_bonus_h_logs_insights_queries" {
  description = "Create saved CloudWatch Logs Insights queries for the incident runbook."
  type        = bool
  default     = true
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

variable "enable_waf_sampled_requests_only" {
  description = "If true, students can optionally filter/redact fields later. (Placeholder toggle.)"
  type        = bool
  default     = false
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

variable "waf_log_destination" {
  description = "Choose ONE destination per WebACL: cloudwatch | s3 | firehose"
  type        = string
  default     = "cloudwatch"

  validation {
    condition     = contains(["cloudwatch", "s3", "firehose"], var.waf_log_destination)
    error_message = "waf_log_destination must be one of: cloudwatch, s3, firehose."
  }
}

variable "waf_log_retention_days" {
  description = "Retention for WAF CloudWatch log group."
  type        = number
  default     = 14
}