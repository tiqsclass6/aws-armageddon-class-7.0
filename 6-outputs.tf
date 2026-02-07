output "application_access_public" {
  description = "Public access instructions via ALB (Bonus B)"
  value       = <<EOT
Application is now accessible publicly via ALB (HTTPS only - Port 443):

Home:           https://${local.fqdn}/
Initialize DB:  https://${local.fqdn}/init
First note:     https://${local.fqdn}/add?note=test_from_route53
Second note:    https://${local.fqdn}/add?note=blue_book_gentlemen
Third note:     https://${local.fqdn}/add?note=brazil_colombia_capeverde
Fourth note:    https://${local.fqdn}/add?note=this_is_250k_work
Fifth note:     https://${local.fqdn}/add?note=lab_1c_bonus_b_is_successful
List notes:     https://${local.fqdn}/list

DNS records and ACM validation may take up to 30 minutes to propagate.
EOT
}

output "application_access_private" {
  description = "Fallback SSM port forwarding instructions (Original access method)"
  value       = <<EOT
The application is also still accessible via SSM port forwarding:

1. aws ssm start-session \
     --target ${aws_instance.lab_ec2.id} \
     --document-name AWS-StartPortForwardingSession \
     --parameters '{"portNumber":["80"],"localPortNumber":["80"]}' \
     --region ${local.region}

2. Open in browser:
   http://localhost:80/
   http://localhost:80/init
   http://localhost:80/add?note=test_from_SSM
   http://localhost:80/add?note=blue_book_gentlemen
   http://localhost:80/add?note=brazil_colombia_capeverde
   http://localhost:80/add?note=this_is_250k_work
   http://localhost:80/add?note=lab_1c_bonus_b_is_successful
   http://localhost:80/list
EOT
}

output "alb_dns_name" {
  description = "DNS name of the internet-facing ALB"
  value       = aws_lb.lab1c_alb.dns_name
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.tg.arn
}

output "app_fqdn" {
  description = "Fully qualified domain name of the application"
  value       = local.fqdn
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.dashboard.dashboard_name
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for application logs"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.lab_ec2.id
}

output "ec2_is_private" {
  description = "Confirms the instance has no public IP"
  value       = aws_instance.lab_ec2.public_ip == null ? "true" : "false"
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint (internal VPC access only)"
  value       = aws_db_instance.lab_rds.endpoint
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  value       = aws_secretsmanager_secret.db_creds.arn
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for database incident alerts"
  value       = aws_sns_topic.db_incidents.arn
}

output "vpc_endpoint_ids" {
  description = "IDs of the created VPC Interface Endpoints"
  value = {
    ssm            = aws_vpc_endpoint.ssm.id
    ec2messages    = aws_vpc_endpoint.ec2messages.id
    ssmmessages    = aws_vpc_endpoint.ssmmessages.id
    logs           = aws_vpc_endpoint.logs.id
    secretsmanager = aws_vpc_endpoint.secretsmanager.id
    s3             = aws_vpc_endpoint.s3.id
    kms            = try(aws_vpc_endpoint.kms.id, "not created")
  }
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL (if enabled)"
  value       = var.enable_waf ? aws_wafv2_web_acl.waf[0].arn : null
}