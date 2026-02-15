locals {
  project_name      = "lab-1c"
  vpc_cidr          = "10.240.0.0/16"
  instance_type     = "t3.micro"
  db_instance_class = "db.t3.micro"
  db_name           = "labdb"
  db_username       = "admin"
  fqdn              = var.domain_name
  my_ip_cidr        = "${chomp(data.http.my_public_ip.response_body)}/32"
  region            = "us-east-1"
  secret_name       = "lab/rds/mysql_v21"
  zone_id           = data.aws_route53_zone.selected.zone_id

  tags = {
    Project     = local.project_name
    Environment = "lab"
    ManagedBy   = "Terraform"
  }
}