output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}

output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.lab_2b.domain_name
}

output "app_url" {
  description = "Application URLs"
  value = {
    app    = "https://${var.app_subdomain}.${var.domain_name}"
    origin = "https://origin.${var.domain_name}"
  }
}