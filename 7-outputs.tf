output "application_access_public" {
  description = "Public access instructions via ALB (Bonus C)"
  value       = <<EOT
Application is now accessible publicly via ALB (HTTPS):

Home:           https://${local.zone_name}/
Initialize DB:  https://${local.zone_name}/init
First note:     https://${local.zone_name}/add?note=test_from_bonus_c
Second note:    https://${local.zone_name}/add?note=blue_book_gentlemen
Third note:     https://${local.zone_name}/add?note=brazil_colombia_capeverde
Fourth note:    https://${local.zone_name}/add?note=this_is_275k_work
Fifth note:     https://${local.zone_name}/add?note=lab_1c_bonus_c_is_successful
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
   http://localhost:80/add?note=lab_1c_bonus_c_is_successful
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
  value       = local.zone_name
}