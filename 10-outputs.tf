output "application_access_public" {
  description = "Public access instructions via CloudFront (Lab 2A)"
  value       = <<EOT
Application is now accessible publicly via CloudFront (HTTPS):

Home:           https://${var.domain_name}/
Initialize DB:  https://${var.domain_name}/init
First note:     https://${var.domain_name}/add?note=test_from_lab_2a
Second note:    https://${var.domain_name}/add?note=blue_book_gentlemen
Third note:     https://${var.domain_name}/add?note=brazil_colombia_capeverde
Fourth note:    https://${var.domain_name}/add?note=this_is_275k_work
Fifth note:     https://${var.domain_name}/add?note=lab_2a_is_successful
List notes:     https://${var.domain_name}/list

(Behind the scenes: CloudFront (+WAF) -> origin-cloaked ALB -> private EC2 -> RDS)
EOT
}

output "application_lb_dns_name" {
  value       = aws_lb.lab_2a_alb.dns_name
  description = "DNS name of the ALB (for direct access if needed)"
}

output "cloudfront_distribution_id" {
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.lab2_cloudfront[0].id : null
  description = "CloudFront distribution id"
}

output "cloudfront_domain_name" {
  value       = var.enable_cloudfront ? aws_cloudfront_distribution.lab2_cloudfront[0].domain_name : null
  description = "CloudFront distribution domain name"
}