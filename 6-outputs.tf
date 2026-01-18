output "application_access_instructions" {
  description = "Instructions for accessing the private application via SSM port forwarding"
  value       = <<EOT
The application is running on a private EC2 instance (no public IP).

To access it from your local machine:

1. Start an SSM port forwarding session:
   aws ssm start-session \
     --target ${aws_instance.lab_ec2.id} \
     --document-name AWS-StartPortForwardingSession \
     --parameters '{"portNumber":["8000"],"localPortNumber":["8000"]}' \
     --region ${local.region}

2. Once the session is established, open these URLs in your local browser:

   Home:           http://localhost:8000/
   Initialize DB:  http://localhost:8000/init
   First note:     http://localhost:8000/add?note=test_from_SSM
   Second note:    http://localhost:8000/add?note=blue_book_gentlemen
   Third note:     http://localhost:8000/add?note=brazil_colombia_capeverde
   Fourth note:    http://localhost:8000/add?note=this_is_250k_work
   Fifth note:     http://localhost:8000/add?note=lab_1c_bonus_a_is_successful
   List notes:     http://localhost:8000/list

Note: The forwarding session must remain active while using the application.
EOT
}

output "ec2_instance_id" {
  description = "EC2 Instance ID for SSM Session Manager access"
  value       = aws_instance.lab_ec2.id
}

output "ec2_is_private" {
  description = "Confirms the instance has no public IP (should be null)"
  value       = aws_instance.lab_ec2.public_ip
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for application logs"
  value       = aws_cloudwatch_log_group.app_logs.name
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
    kms            = try(aws_vpc_endpoint.kms[0].id, "not created")
  }
}