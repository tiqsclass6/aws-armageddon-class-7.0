# Output for Liberdade Application Load Balancer DNS name
output "liberdade_alb_dns_name" {
  description = "Application Load Balancer DNS name in Liberdade"
  value       = aws_lb.liberdade_alb.dns_name
}

# Output for Liberdade Application URLs
output "liberdade_application_urls" {
  value = <<EOT
Initialize DB:    https://${aws_cloudfront_distribution.liberdade_cf.domain_name}/init
1st Note (GET):   https://${aws_cloudfront_distribution.liberdade_cf.domain_name}/add?note=first_note
2nd Note (GET):   https://${aws_cloudfront_distribution.liberdade_cf.domain_name}/add?note=blue_book_gentlemen
3rd Note (GET):   https://${aws_cloudfront_distribution.liberdade_cf.domain_name}/add?note=TIQS_loves_big_booty_latinas
4th Note (GET):   https://${aws_cloudfront_distribution.liberdade_cf.domain_name}/add?note=brazil_colombia_capeverde
5th Note (GET):   https://${aws_cloudfront_distribution.liberdade_cf.domain_name}/add?note=this_is_300k_work
6th Note (GET):   https://${aws_cloudfront_distribution.liberdade_cf.domain_name}/add?note=armageddon_is_not_bad
7th Note (GET):   https://${aws_cloudfront_distribution.liberdade_cf.domain_name}/add?note=terraform_rocks
8th Note (GET):   https://${aws_cloudfront_distribution.liberdade_cf.domain_name}/add?note=cloudfront_with_alb_using_tgws
9th Note (GET):   https://${aws_cloudfront_distribution.liberdade_cf.domain_name}/add?note=the_end_is_near
Final Note (GET): https://${aws_cloudfront_distribution.liberdade_cf.domain_name}/add?note=lab_3b_is_complete
List Notes:       https://${aws_cloudfront_distribution.liberdade_cf.domain_name}/list
EOT
}

# Output for Liberdade Auto Scaling Group name
output "liberdade_asg_name" {
  description = "Auto Scaling Group name in Liberdade"
  value       = aws_autoscaling_group.liberdade_asg.name
}

# Output for Liberdade CloudFront distribution domain name
output "liberdade_cloudfront_domain" {
  description = "CloudFront distribution domain name in Liberdade"
  value       = aws_cloudfront_distribution.liberdade_cf.domain_name
}

# Output for Liberdade Transit Gateway ID
output "liberdade_tgw_id" {
  description = "Liberdade Transit Gateway ID"
  value       = aws_ec2_transit_gateway.liberdade_tgw.id
}

# Output for Liberdade VPC CIDR block
output "liberdade_vpc_cidr" {
  description = "Liberdade VPC CIDR block"
  value       = aws_vpc.liberdade.cidr_block
}

# Output for Shinjuku RDS credentials secret ARN
output "shinjuku_db_secret_arn" {
  description = "The ARN of the Shinjuku RDS credentials secret"
  value       = aws_secretsmanager_secret.shinjuku_db_creds_v13.arn
}

# Output for Shinjuku RDS endpoint
output "shinjuku_rds_endpoint" {
  description = "The endpoint address of the Shinjuku RDS instance"
  value       = aws_db_instance.shinjuku.address
}

# Output for Shinjuku Transit Gateway ID
output "shinjuku_tgw_id" {
  description = "The ID of the Shinjuku Transit Gateway"
  value       = aws_ec2_transit_gateway.shinjuku_tgw.id
}

# Output for Shinjuku VPC CIDR block
output "shinjuku_vpc_cidr" {
  description = "The CIDR block of the Shinjuku VPC"
  value       = aws_vpc.shinjuku.cidr_block
}

# Output for Liberdade origin header name and value
output "liberdade_origin_header_name" {
  value = var.origin_header_name
}

output "liberdade_origin_header_value" {
  sensitive = true
  value     = random_password.origin_header_value.result
}