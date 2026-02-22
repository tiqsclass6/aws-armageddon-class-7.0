data "aws_route53_zone" "root" {
  name         = "${var.domain_name}."
  private_zone = false
}

data "aws_elb_service_account" "lab_2a" {}

# Apex/root Alias A -> CloudFront
resource "aws_route53_record" "apex_alias_to_cloudfront" {
  zone_id = data.aws_route53_zone.root.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.lab2_cloudfront[0].domain_name
    zone_id                = aws_cloudfront_distribution.lab2_cloudfront[0].hosted_zone_id
    evaluate_target_health = false
  }
}

# app.<domain> Alias A -> CloudFront
resource "aws_route53_record" "app_alias_to_cloudfront" {
  count   = var.create_app_record ? 1 : 0
  zone_id = data.aws_route53_zone.root.zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.lab2_cloudfront[0].domain_name
    zone_id                = aws_cloudfront_distribution.lab2_cloudfront[0].hosted_zone_id
    evaluate_target_health = false
  }
}