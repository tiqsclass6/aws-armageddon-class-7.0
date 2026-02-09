data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "http" "my_public_ip" {
  url = "https://ipv4.icanhazip.com"
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "sa-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
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

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "lab-1c"
}

variable "aws_sns_topic_subscription_email_alert_endpoint" {
  description = "Email endpoint for SNS topic subscription"
  type        = string
  default     = "bjett2000@hotmail.com"
}

variable "aws_key_pair_name" {
  description = "Name of the existing AWS Key Pair to use for EC2 instances"
  type        = string
  default     = "lab-ec2-app"
}