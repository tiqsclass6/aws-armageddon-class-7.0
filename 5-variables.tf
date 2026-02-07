data "aws_region" "current" {}

data "aws_route53_zone" "main" {
  name         = "${var.domain_name}."
  private_zone = false
}

data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

variable "alb_acm_certificate_arn" {
  description = "ARN of ACM certificate in us-east-2 for ALB HTTPS listener"
  type        = string
  default     = "arn:aws:acm:us-east-2:866340886126:certificate/f66f0384-bdb3-48e2-8e90-7443faa0ccc8"

  validation {
    condition     = can(regex("^arn:aws:acm:us-east-2:[0-9]{12}:certificate/", var.alb_acm_certificate_arn))
    error_message = "ALB certificate must be created in us-east-2 region."
  }
}

variable "cloudfront_acm_certificate_arn" {
  description = "ARN of ACM certificate in us-east-1 for CloudFront"
  type        = string
  default     = "arn:aws:acm:us-east-1:866340886126:certificate/9e091531-3230-42ff-b5f4-468d0031d795"

  validation {
    condition     = can(regex("^arn:aws:acm:us-east-1:[0-9]{12}:certificate/", var.cloudfront_acm_certificate_arn))
    error_message = "CloudFront certificate must be created in us-east-1 region."
  }
}

variable "app_subdomain" {
  type    = string
  default = "app"
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "az_suffixes" {
  type    = list(string)
  default = ["a", "b"]
}

variable "db_engine" {
  type    = string
  default = "mysql"
}

variable "db_engine_version" {
  type        = string
  description = "Optional. Leave blank to let AWS select a supported default."
  default     = ""
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

variable "db_name" {
  type    = string
  default = "lab2a"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "db_multi_az" {
  type    = bool
  default = false
}

variable "domain_name" {
  type    = string
  default = "theinternationalquietstorm.com"
}

variable "name_prefix" {
  type    = string
  default = "lab-2a"
}

variable "public_subnet_cidrs" {
  type = list(string)
  default = [
    "10.240.1.0/24",
    "10.240.2.0/24"
  ]
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = [
    "10.240.11.0/24",
    "10.240.12.0/24"
  ]
}

variable "vpc_cidr" {
  type    = string
  default = "10.240.0.0/16"
}

variable "web_instance_count" {
  type    = number
  default = 2
}

variable "web_instance_type" {
  type    = string
  default = "t3.micro"
}
