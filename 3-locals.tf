locals {
  project_name      = "lab-1c"
  vpc_cidr          = "10.240.0.0/16"
  instance_type     = "t3.micro"
  db_instance_class = "db.t3.micro"
  db_name           = "labdb"
  db_username       = "admin"
  my_ip_cidr        = "${chomp(data.http.my_public_ip.response_body)}/32"
  region            = "sa-east-1"
  secret_name       = "lab/rds/mysql_v16"

  tags = {
    Project     = local.project_name
    Environment = "lab"
    ManagedBy   = "Terraform"
  }
}