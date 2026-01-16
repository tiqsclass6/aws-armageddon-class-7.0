# Outputs
output "application_urls" {
  description = "URLs to test the deployed application"

  value = <<EOT
Home:           http://${aws_instance.lab_ec2.public_ip}/
Initialize DB:  http://${aws_instance.lab_ec2.public_ip}/init
1st note (GET): http://${aws_instance.lab_ec2.public_ip}/add?note=first_note
2nd note (GET)  http://${aws_instance.lab_ec2.public_ip}/add?note=blue_book_gentlemen
3rd note (GET)  http://${aws_instance.lab_ec2.public_ip}/add?note=brazil_colombia_capeverde
4th note (GET)  http://${aws_instance.lab_ec2.public_ip}/add?note=this_is_200k_work
5th note (GET)  http://${aws_instance.lab_ec2.public_ip}/add?note=lab_1c_is_a_success
List notes:     http://${aws_instance.lab_ec2.public_ip}/list
EOT
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for application logs"
  value       = aws_cloudwatch_log_group.app_logs.name
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance to access the application"
  value       = aws_instance.lab_ec2.public_ip
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint (for CLI verification)"
  value       = aws_db_instance.lab_rds.endpoint
}

output "secrets_manager_secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.db_creds.arn
}

output "sns_topic_arn" {
  description = "SNS Topic ARN for incident alerts"
  value       = aws_sns_topic.db_incidents.arn
}