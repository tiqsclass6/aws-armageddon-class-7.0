locals {
  project_name          = "lab-1c"
  vpc_cidr              = "10.240.0.0/16"
  instance_type         = "t3.micro"
  db_instance_class     = "db.t3.micro"
  db_name               = "labdb"
  db_username           = "admin"
  my_ip_cidr            = "${chomp(data.http.my_public_ip.response_body)}/32"
  region                = "us-east-1"
  secret_name           = "lab/rds/mysql_v25"
  waf_cw_log_group_name = "aws-waf-logs-${var.project_name}-web-acl"
  app_log_group         = "/aws/ec2/${var.project_name}-rds-app"
  waf_log_group         = local.waf_cw_log_group_name
  zone_name             = var.domain_name

  tags = {
    Project     = local.project_name
    Environment = "lab"
    ManagedBy   = "Terraform"
  }
}
