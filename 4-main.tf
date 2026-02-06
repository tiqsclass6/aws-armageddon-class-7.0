resource "aws_vpc" "lab_2b" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "lab_2b" {
  vpc_id = aws_vpc.lab_2b.id
  tags   = { Name = "${local.name_prefix}-igw" }
}

# Public Subnets
resource "aws_subnet" "public" {
  for_each = local.az_map

  vpc_id                  = aws_vpc.lab_2b.id
  cidr_block              = each.value.cidr
  availability_zone       = each.key
  map_public_ip_on_launch = true

  tags = {
    Name = "${each.value.name}-public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab_2b.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_2b.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Security Groups
resource "aws_security_group" "alb_sg" {
  name        = "${local.name_prefix}-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.lab_2b.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "${local.name_prefix}-ec2-sg"
  description = "EC2 security group"
  vpc_id      = aws_vpc.lab_2b.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ec2-sg"
  }
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = var.instance_type
  subnet_id                   = values(aws_subnet.public)[0].id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user_data.sh")
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name

  tags = {
    Name = "${local.name_prefix}-web"
  }
}

# Application Load Balancer
resource "aws_lb" "app_alb" {
  name               = "${local.name_prefix}-alb"
  load_balancer_type = "application"
  subnets            = values(aws_subnet.public)[*].id
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${local.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab_2b.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${local.name_prefix}-tg"
  }
}

resource "aws_lb_target_group_attachment" "app_attach" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.web.id
  port             = 80
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_443" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.alb_cert_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  depends_on = [
    aws_acm_certificate_validation.alb_cert_validation
  ]
}

resource "aws_iam_role" "ec2_ssm_role" {
  name = "${local.name_prefix}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = data.aws_iam_policy.ssm_core.arn
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "${local.name_prefix}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "lab_2b" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name = "origin.${var.domain_name}"
    origin_id   = "${local.name_prefix}-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "${local.name_prefix}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.lab_2b_cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.lab_2b_orp_api01.id
  }

  ordered_cache_behavior {
    path_pattern           = "/static/*"
    target_origin_id       = "${local.name_prefix}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id            = aws_cloudfront_cache_policy.lab_2b_cache_static01.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.lab_2b_orp_static01.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.lab_2b_rsp_static01.id
  }

  ordered_cache_behavior {
    path_pattern           = "/api/public-feed"
    target_origin_id       = "${local.name_prefix}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = data.aws_cloudfront_cache_policy.use_origin_cache_control.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.lab_2b_orp_api01.id
  }

  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "${local.name_prefix}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.lab_2b_cache_api_disabled01.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.lab_2b_orp_api01.id
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cf_cert_validation.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = ["${var.app_subdomain}.${var.domain_name}"]

  depends_on = [
    aws_route53_record.origin,
    aws_lb_listener.https_443
  ]

  tags = {
    Name = "${local.name_prefix}-cf"
  }
}

resource "aws_cloudfront_cache_policy" "lab_2b_cache_static01" {
  name        = "${local.name_prefix}-cache-static01"
  comment     = "Aggressive caching for /static/*"
  default_ttl = 86400
  max_ttl     = 31536000
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    enable_accept_encoding_gzip   = false
    enable_accept_encoding_brotli = false
  }
}

resource "aws_cloudfront_cache_policy" "lab_2b_cache_api_disabled01" {
  name        = "${local.name_prefix}-cache-api-disabled01"
  comment     = "Disable caching by default for API/dynamic paths"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = false
    enable_accept_encoding_brotli = false

    cookies_config {
      cookie_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "lab_2b_orp_api01" {
  name    = "${local.name_prefix}-orp-api01"
  comment = "Forward necessary values for API calls (minimal, safe)"

  cookies_config {
    cookie_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "none"
  }

  headers_config {
    header_behavior = "none"
  }
}

resource "aws_cloudfront_origin_request_policy" "lab_2b_orp_static01" {
  name    = "${local.name_prefix}-orp-static01"
  comment = "Minimal forwarding for static assets"

  cookies_config {
    cookie_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "all"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Host",
        "Origin",
        "Content-Type"
      ]
    }
  }
}

resource "aws_cloudfront_response_headers_policy" "lab_2b_rsp_static01" {
  name    = "${local.name_prefix}-rsp-static01"
  comment = "Stamp Cache-Control for static content"

  custom_headers_config {
    items {
      header   = "Cache-Control"
      override = true
      value    = "public, max-age=86400, immutable"
    }
  }
}

resource "terraform_data" "break_glass_invalidation" {
  count = var.break_glass_invalidate ? 1 : 0

  input = {
    distribution_id = aws_cloudfront_distribution.lab_2b.id
    paths           = var.break_glass_paths
  }

  provisioner "local-exec" {
    interpreter = ["bash", "-lc"]

    command = <<EOT
aws cloudfront create-invalidation \
  --distribution-id "${self.input.distribution_id}" \
  --invalidation-batch '{
    "Paths": { "Quantity": ${length(self.input.paths)}, "Items": ${jsonencode(self.input.paths)} },
    "CallerReference": "tf-break-glass-${timestamp()}"
  }'
EOT
  }
}

resource "aws_acm_certificate" "alb_cert" {
  domain_name       = "origin.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "alb_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "alb_cert_validation" {
  certificate_arn         = aws_acm_certificate.alb_cert.arn
  validation_record_fqdns = [for r in aws_route53_record.alb_cert_validation : r.fqdn]
}

# ACM Certificate (must be us-east-1 for CloudFront)
resource "aws_acm_certificate" "cf_cert" {
  provider          = aws.us-east-1
  domain_name       = "${var.app_subdomain}.${var.domain_name}"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "cf_cert_validation" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.cf_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cf_cert.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Route53 alias to CloudFront
resource "aws_route53_record" "app_subdomain" {
  zone_id = var.route53_zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.lab_2b.domain_name
    zone_id                = aws_cloudfront_distribution.lab_2b.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "apex" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.lab_2b.domain_name
    zone_id                = aws_cloudfront_distribution.lab_2b.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "origin" {
  zone_id = var.route53_zone_id
  name    = "origin.${var.domain_name}"
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.app_alb.dns_name]
}

resource "aws_route53_record" "www" {
  zone_id = var.route53_zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.lab_2b.domain_name
    zone_id                = aws_cloudfront_distribution.lab_2b.hosted_zone_id
    evaluate_target_health = false
  }
}