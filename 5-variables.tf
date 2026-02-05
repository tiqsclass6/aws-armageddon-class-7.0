data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_iam_policy" "ssm_core" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_route53_zone" "primary" {
  name         = "${var.domain_name}."
  private_zone = false
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
  default = ["a", "b", "c"]
}

variable "break_glass_invalidate" {
  description = "Set true ONLY for approved break-glass invalidation events."
  type        = bool
  default     = false
}

variable "break_glass_paths" {
  description = "Paths to invalidate (smallest blast radius possible)."
  type        = list(string)
  default     = ["/static/index.html"]
}

variable "domain_name" {
  type    = string
  default = "theinternationalquietstorm.com"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "name_prefix" {
  type    = string
  default = "lab-2b"
}

variable "route53_zone_id" {
  description = "The Route53 Hosted Zone ID for the domain"
  type        = string
  default     = "Z0600028113170IXLDLQ1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.240.0.0/16"
}