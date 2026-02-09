output "application_access_public" {
  description = "Public access instructions via ALB (Bonus C)"
  value       = <<EOT
Application is now accessible publicly via ALB (HTTPS):

Home:           https://${local.zone_name}/
Initialize DB:  https://${local.zone_name}/init
First note:     https://${local.zone_name}/add?note=test_from_bonus_h
Second note:    https://${local.zone_name}/add?note=blue_book_gentlemen
Third note:     https://${local.zone_name}/add?note=brazil_colombia_capeverde
Fourth note:    https://${local.zone_name}/add?note=this_is_275k_work
Fifth note:     https://${local.zone_name}/add?note=lab_1c_bonus_h_is_successful
List notes:     https://${local.zone_name}/list

DNS + ACM validation can take 5-30 minutes to propagate.
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
   http://localhost:80/add?note=this_is_275k_work
   http://localhost:80/add?note=lab_1c_bonus_h_is_successful
   http://localhost:80/list
EOT
}

output "bonus_h_logs_insights_waf_log_group" {
  value       = local.waf_cw_log_group_name
  description = "WAF CloudWatch log group used by Logs Insights queries."
}

output "bonus_h_logs_insights_app_log_group" {
  value       = "/aws/ec2/${var.project_name}-rds-app"
  description = "App CloudWatch log group used by Logs Insights queries."
}

output "bonus_h_ir_reports_bucket" {
  value = aws_s3_bucket.bonus_h_ir_reports[0].bucket
}
