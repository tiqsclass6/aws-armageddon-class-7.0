resource "aws_vpc" "lab_2a" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

resource "aws_internet_gateway" "lab_2a" {
  vpc_id = aws_vpc.lab_2a.id
  tags   = { Name = "${local.name_prefix}-igw" }
}

# Public Subnets
resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.lab_2a.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = each.value.name
    Type = "public"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.lab_2a.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.value.name
    Type = "private"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab_2a.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lab_2a.id
  }

  tags = { Name = "${local.name_prefix}-public-rt" }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT Gateway (single, placed in first public subnet)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${local.name_prefix}-nat-eip" }
}

resource "aws_nat_gateway" "lab_2a" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[keys(local.public_subnets)[0]].id

  tags = { Name = "${local.name_prefix}-nat-gw" }

  depends_on = [aws_internet_gateway.lab_2a]
}

# Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.lab_2a.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lab_2a.id
  }

  tags = { Name = "${local.name_prefix}-private-rt" }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# Security Group for ALB
resource "aws_security_group" "lab_2a_alb_sg" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for ALB - allow inbound 443 only from CloudFront origin-facing prefix list"
  vpc_id      = aws_vpc.lab_2a.id

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

# ALB Ingress CloudFront HTTPS
resource "aws_security_group_rule" "alb_ingress_cloudfront_443" {
  type              = "ingress"
  security_group_id = aws_security_group.lab_2a_alb_sg.id

  from_port       = 443
  to_port         = 443
  protocol        = "tcp"
  prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id]

  description = "Allow HTTPS traffic only from CloudFront origin-facing IP ranges"
}

resource "aws_security_group_rule" "alb_ingress_public_443_for_lab_test" {
  type              = "ingress"
  security_group_id = aws_security_group.lab_2a_alb_sg.id

  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  description = "LAB TEST ONLY: allow 443 to ALB so missing-origin-header returns 403 (not timeout)"
}

# ALB Egress All
resource "aws_security_group_rule" "alb_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.lab_2a_alb_sg.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  description = "Allow all outbound traffic from ALB"
}

resource "aws_security_group" "web_sg" {
  name        = "${local.name_prefix}-web-sg"
  description = "Private web instances; only ALB can reach port 80"
  vpc_id      = aws_vpc.lab_2a.id

  tags = { Name = "${local.name_prefix}-web-sg" }
}

resource "aws_security_group_rule" "web_ingress_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.web_sg.id
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lab_2a_alb_sg.id
  description              = "Allow HTTP from ALB only"
}

resource "aws_security_group_rule" "web_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.web_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "rds_sg" {
  name        = "${local.name_prefix}-rds-sg"
  description = "RDS security group; only web instances can reach"
  vpc_id      = aws_vpc.lab_2a.id
  tags        = { Name = "${local.name_prefix}-rds-sg" }
}

resource "aws_security_group_rule" "rds_ingress_from_web" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds_sg.id
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.web_sg.id
  description              = "DB access from web instances only"
}

resource "aws_security_group_rule" "rds_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.rds_sg.id
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# Target Group
resource "aws_lb_target_group" "lab_2a_tg" {
  name        = "${local.name_prefix}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.lab_2a.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${local.name_prefix}-tg"
  }
}

resource "aws_lb_target_group_attachment" "web" {
  count            = var.web_instance_count
  target_group_arn = aws_lb_target_group.lab_2a_tg.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}

# Application Load Balancer
resource "aws_lb" "lab_2a_alb" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lab_2a_alb_sg.id]
  subnets            = [for s in aws_subnet.public : s.id]

  enable_deletion_protection = false

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

# HTTPS Listener
resource "aws_lb_listener" "lab_2a_https_listener" {
  load_balancer_arn = aws_lb.lab_2a_alb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.alb_acm_certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden - Missing required origin header"
      status_code  = "403"
    }
  }
}

# HTTP Listener - Redirect to HTTPS
resource "aws_lb_listener" "lab_2a_http_listener" {
  load_balancer_arn = aws_lb.lab_2a_alb.arn
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

# Origin Header Enforcement Listener Rules
resource "aws_lb_listener_rule" "require_origin_header" {
  listener_arn = aws_lb_listener.lab_2a_https_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lab_2a_tg.arn
  }

  condition {
    http_header {
      http_header_name = "X-Lab2a-Origin-Secret"
      values           = [random_password.origin_header_secret.result]
    }
  }
}

resource "aws_iam_role" "ssm_role" {
  name               = "${local.name_prefix}-ssm-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume.json
}

data "aws_iam_policy_document" "ec2_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${local.name_prefix}-ssm-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_instance" "web" {
  count = var.web_instance_count

  ami                    = data.aws_ami.al2023.id
  instance_type          = var.web_instance_type
  subnet_id              = values(aws_subnet.private)[count.index % length(aws_subnet.private)].id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_profile.name

  user_data = file("${path.module}/germany.sh")

  tags = {
    Name = "${local.name_prefix}-web-${count.index}"
  }
}

# Random DB Password
resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*+-=?^_"
}

# Random Password for Origin Header
resource "random_password" "origin_header_secret" {
  length           = 40
  special          = false
  override_special = "!#$%&*+-=?^_"
}

# RDS Subnet Group
resource "aws_db_subnet_group" "lab_2a" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = [for s in aws_subnet.private : s.id]

  tags = { Name = "${local.name_prefix}-db-subnets" }
}

# RDS DB Instance
resource "aws_db_instance" "lab_2a" {
  identifier        = "${local.name_prefix}-db"
  engine            = var.db_engine
  engine_version    = var.db_engine_version != "" ? var.db_engine_version : null
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  db_name           = var.db_name
  username          = var.db_username
  password          = random_password.db_password.result
  port              = var.db_port

  db_subnet_group_name   = aws_db_subnet_group.lab_2a.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  skip_final_snapshot = true

  tags = { Name = "${local.name_prefix}-db" }
}

# WAF – CloudFront scope
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  provider = aws.us-east-1
  name     = "${local.name_prefix}-cf-waf"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${local.name_prefix}-cf-waf"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "RateLimit"
    priority = 10

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.name_prefix}-cf-rate"
      sampled_requests_enabled   = true
    }
  }
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "lab_2a" {
  default_root_object = "index.html"
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${local.name_prefix} - frontend distribution"
  wait_for_deployment = false

  origin {
    origin_id   = "${local.name_prefix}-alb-origin"
    domain_name = aws_lb.lab_2a_alb.dns_name

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-Lab2a-Origin-Secret"
      value = random_password.origin_header_secret.result
    }
  }

  default_cache_behavior {
    target_origin_id       = "${local.name_prefix}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods  = ["GET", "HEAD"]

    cache_policy_id          = aws_cloudfront_cache_policy.alb_dynamic.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.alb_all.id
  }

  web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn

  aliases = [
    var.domain_name,
    "${var.app_subdomain}.${var.domain_name}"
  ]

  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_cloudfront_cache_policy" "alb_dynamic" {
  name        = "${local.name_prefix}-alb-dynamic"
  comment     = "Caching disabled for dynamic ALB origin"
  default_ttl = 0
  max_ttl     = 0
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    # Must be false when caching is disabled (TTL=0)
    enable_accept_encoding_gzip   = false
    enable_accept_encoding_brotli = false

    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

resource "aws_cloudfront_origin_request_policy" "alb_all" {
  name    = "${local.name_prefix}-alb-req"
  comment = "Forward selected viewer headers + all cookies + all query strings to ALB"

  cookies_config {
    cookie_behavior = "all"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = [
        "Host",
        "Origin",
        "Referer",
        "User-Agent",
        "Accept",
        "Accept-Language",
        "CloudFront-Viewer-Country"
      ]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

# Route 53 records pointing to CloudFront
resource "aws_route53_record" "apex" {
  zone_id = local.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.lab_2a.domain_name
    zone_id                = aws_cloudfront_distribution.lab_2a.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "app_subdomain" {
  zone_id = local.route53_zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.lab_2a.domain_name
    zone_id                = aws_cloudfront_distribution.lab_2a.hosted_zone_id
    evaluate_target_health = false
  }
}