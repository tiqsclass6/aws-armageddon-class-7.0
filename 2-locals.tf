locals {
  cloudfront_domain = aws_cloudfront_distribution.liberdade_cf.domain_name
  project_name      = "lab-3a"
  liberdade_prefix  = "liberdade"
  shinjuku_prefix   = "shinjuku"

  liberdade_vpc_cidr = "10.245.0.0/16"
  shinjuku_vpc_cidr  = "10.240.0.0/16"

  liberdade_private_route_table_ids = [aws_route_table.liberdade_private.id]
  shinjuku_private_route_table_ids  = [aws_route_table.shinjuku_private.id]

  tags = {
    Project     = local.project_name
    Environment = "lab-3a"
    ManagedBy   = "Terraform"
  }
}