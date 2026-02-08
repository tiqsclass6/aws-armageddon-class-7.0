data "aws_route53_zone" "root" {
  name         = "${var.domain_name}."
  private_zone = false
}

# Apex/root Alias A -> ALB
resource "aws_route53_record" "apex_alias_to_alb" {
  zone_id = data.aws_route53_zone.root.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.lab1c_alb.dns_name
    zone_id                = aws_lb.lab1c_alb.zone_id
    evaluate_target_health = true
  }
}

# Optional: app.<domain> Alias A -> ALB
resource "aws_route53_record" "app_alias_to_alb" {
  count   = var.create_app_record ? 1 : 0
  zone_id = data.aws_route53_zone.root.zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.lab1c_alb.dns_name
    zone_id                = aws_lb.lab1c_alb.zone_id
    evaluate_target_health = true
  }
}