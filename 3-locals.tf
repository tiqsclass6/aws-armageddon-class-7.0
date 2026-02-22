locals {
  project_name          = var.project_name
  vpc_cidr              = "10.240.0.0/16"
  instance_type         = var.instance_type
  db_instance_class     = var.db_instance_class
  db_name               = "labdb"
  db_username           = "admin"
  my_ip_cidr            = "${chomp(data.http.my_public_ip.response_body)}/32"
  region                = data.aws_region.current.id
  secret_name           = "lab/rds/mysql_v26"
  waf_cw_log_group_name = "aws-waf-logs-${var.project_name}-web-acl"
  waf_log_group         = local.waf_cw_log_group_name
  app_log_group         = "/aws/ec2/${var.project_name}-rds-app"
  zone_name             = var.domain_name

  cloudfront_cert_validation_records = {
    for dvo in aws_acm_certificate.cloudfront_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  tags = {
    Project     = local.project_name
    Environment = "lab-2a"
    ManagedBy   = "Terraform"
  }
}