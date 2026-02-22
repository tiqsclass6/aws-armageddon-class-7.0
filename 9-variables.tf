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

variable "aws_sns_topic_subscription_email_alert_endpoint" {
  description = "Email endpoint for SNS subscription alerts"
  type        = string
  default     = "bjett2000@hotmail.com"
}

variable "domain_name" {
  description = "Domain name for Route 53 and CloudFront aliases"
  type        = string
  default     = "theinternationalquietstorm.com"
}

variable "app_subdomain" {
  description = "Subdomain for the application"
  type        = string
  default     = "app"
}

variable "create_app_record" {
  type        = bool
  description = "Also create app.<domain> Alias A"
  default     = true
}

variable "db_allocated_storage" {
  description = "RDS allocated storage (GB)"
  type        = number
  default     = 20
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "enable_alb_access_logs" {
  description = "Enable ALB access logging to S3"
  type        = bool
  default     = true
}

variable "enable_lab_2a_logs_insights_queries" {
  description = "Enable CW Logs Insights query definitions for Lab 2A"
  type        = bool
  default     = true
}

variable "enable_lab_2a_bedrock_auto_ir" {
  description = "Enable Bedrock-based auto incident report resources"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Enable AWS WAF on the ALB (Lab 2A expects false)"
  type        = bool
  default     = false
}

variable "enable_cf_waf" {
  description = "Enable CLOUDFRONT-scoped WAF on CloudFront"
  type        = bool
  default     = true
}

variable "enable_cloudfront" {
  description = "Enable CloudFront distribution in front of ALB"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "lab_2a_reports_bucket_name" {
  description = "Optional bucket name override for Lab 2A IR reports"
  type        = string
  default     = ""
}

variable "lab_2a_bedrock_model_id_primary" {
  description = "Primary Bedrock model id for Bonus G (Claude). Requires model access approval in the account/region."
  type        = string
  default     = "anthropic.claude-3-5-sonnet-20240620-v1:0"
}

variable "lab_2a_bedrock_model_id_fallback" {
  description = "Fallback Bedrock model id for Bonus G (use a model that is enabled and not EOL)."
  type        = string
  default     = "us.amazon.nova-lite-v1:0"
}

variable "origin_header_name" {
  description = "Secret header name that CloudFront injects and ALB requires"
  type        = string
  default     = "X-Chewbacca-Growl"
}

variable "origin_header_length" {
  description = "Length for secret origin header value"
  type        = number
  default     = 32
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "lab-2a"
}

variable "region" {
  description = "AWS region for deployment (your stack region)."
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
  default     = 30
}