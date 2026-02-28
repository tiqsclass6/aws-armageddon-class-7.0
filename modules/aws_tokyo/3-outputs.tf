output "aws_bgp_asn" {
  description = "AWS TGW BGP ASN"
  value       = var.aws_bgp_asn
}

output "private_route_table_id" {
  description = "The ID of the private route table created in Tokyo region."
  value       = aws_route_table.tokyo_private.id
}

output "rds_endpoint" {
  description = "Tokyo RDS endpoint (hostname)"
  value       = var.enable_rds ? aws_db_instance.tokyo_rds[0].address : null
}

output "rds_port" {
  description = "Tokyo RDS port"
  value       = var.rds_port
}

output "rds_db_name" {
  description = "Tokyo RDS database name"
  value       = var.rds_db_name
}

output "rds_username" {
  description = "Tokyo RDS username (non-secret)"
  value       = var.rds_username
}

output "tgw_id" {
  description = "The ID of the TGW created in Tokyo region."
  value       = aws_ec2_transit_gateway.tokyo.id
}

output "tgw_route_table_id" {
  description = "The ID of the TGW route table created in Tokyo region."
  value       = aws_ec2_transit_gateway_route_table.tokyo.id
}

output "vpc_cidr" {
  description = "Tokyo VPC CIDR (PHI region CIDR to advertise over BGP)"
  value       = var.aws_vpc_cidr
}

output "vpc_id" {
  description = "The ID of the VPC created in Tokyo region."
  value       = aws_vpc.tokyo.id
}