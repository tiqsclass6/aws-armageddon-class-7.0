output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.lab_2a_alb.dns_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.lab_2a.id
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.lab_2a.domain_name
}

output "cloudfront_web_acl_arn" {
  description = "WAFv2 Web ACL ARN attached to CloudFront"
  value       = aws_wafv2_web_acl.cloudfront_waf.arn
}

output "route53_urls" {
  description = "All CloudFront front-door URLs"
  value = {
    root_domain   = "https://${var.domain_name}"
    app_subdomain = "https://${var.app_subdomain}.${var.domain_name}"
  }
}
