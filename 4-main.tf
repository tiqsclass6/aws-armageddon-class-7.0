# Custom VPC
resource "aws_vpc" "lab_2a_vpc" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpc"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.lab_2a_vpc.id
  cidr_block              = cidrsubnet(local.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.lab_2a_vpc.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(local.tags, {
    Name = "${var.project_name}-private-subnet-${count.index + 1}"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab_2a_vpc.id

  tags = merge(local.tags, {
    Name = "${var.project_name}-igw"
  })
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab_2a_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table (no NAT – using VPC Endpoints)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.lab_2a_vpc.id

  tags = merge(local.tags, {
    Name = "${var.project_name}-private-rt"
  })
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Security group for private EC2 instance"
  vpc_id      = aws_vpc.lab_2a_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-ec2-sg"
  })
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = aws_vpc.lab_2a_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-rds-sg"
  })
}

resource "aws_security_group" "vpce_sg" {
  name        = "${var.project_name}-vpce-sg"
  description = "Security group for VPC Endpoints"
  vpc_id      = aws_vpc.lab_2a_vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpce-sg"
  })
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.lab_2a_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-alb-sg"
  })
}

resource "aws_security_group" "vpce_https" {
  name        = "${var.project_name}-vpce-https"
  description = "Allow HTTPS to VPC interface endpoints from within VPC"
  vpc_id      = aws_vpc.lab_2a_vpc.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.lab_2a_vpc.cidr_block]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ec2_managed_prefix_list" "cf_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# Allow ALB → EC2
resource "aws_security_group_rule" "ec2_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ec2_sg.id
  source_security_group_id = aws_security_group.alb_sg.id
}

# Allow EC2 → ALB
resource "aws_security_group_rule" "alb_ingress_cloudfront_443" {
  type              = "ingress"
  security_group_id = aws_security_group.alb_sg.id
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"

  prefix_list_ids = [data.aws_ec2_managed_prefix_list.cf_origin_facing.id]
}

# IAM Roles and Policies
resource "aws_iam_role" "ec2_ssm_role" {
  name = "${var.project_name}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "ssm_policy" {
  name = "${local.project_name}-ssm-access"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/lab/db/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "secrets_read" {
  name = "${var.project_name}-secrets-read"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "ReadOnlyOwnSecret"
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      Resource = aws_secretsmanager_secret.db_creds.arn
    }]
  })
}

resource "aws_iam_role_policy" "ssm_labdb_only" {
  name = "${local.project_name}-ssm-labdb-only"
  role = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "ReadLabDbPathOnly"
      Effect = "Allow"
      Action = [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ]
      Resource = "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/lab/db/*"
    }]
  })
}

resource "aws_iam_role_policy" "cloudwatch_logs" {
  count = 1
  name  = "${var.project_name}-cloudwatch-logs"
  role  = aws_iam_role.ec2_ssm_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "WriteSpecificLogGroup"
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ]
      Resource = [
        aws_cloudwatch_log_group.app_logs.arn,
        "${aws_cloudwatch_log_group.app_logs.arn}:*"
      ]
    }]
  })
}

resource "aws_iam_role_policy" "lab_2a_ec2_read_wheels" {
  name = "lab-2a-ec2-read-wheels"
  role = aws_iam_role.ec2_ssm_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListWheelsPrefix"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.project_name}-wheels-866340886126"
        Condition = {
          StringLike = {
            "s3:prefix" = ["wheels/*"]
          }
        }
      },
      {
        Sid    = "GetWheelObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-wheels-866340886126/wheels/*"
      }
    ]
  })
}

# Instance Profile
resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "${var.project_name}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

# VPC Endpoints (Interface + Gateway)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.lab_2a_vpc.id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowWheelsBucketRead"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.project_name}-wheels-866340886126",
          "arn:aws:s3:::${var.project_name}-wheels-866340886126/wheels/*"
        ]
      }
    ]
  })

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpce-s3"
  })
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.lab_2a_vpc.id
  service_name        = "com.amazonaws.${local.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpce-ssm"
  })
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.lab_2a_vpc.id
  service_name        = "com.amazonaws.${local.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpce-ec2messages"
  })
}

resource "aws_vpc_endpoint" "rds" {
  vpc_id              = aws_vpc.lab_2a_vpc.id
  service_name        = "com.amazonaws.${local.region}.rds"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpce-rds"
  })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.lab_2a_vpc.id
  service_name        = "com.amazonaws.${local.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpce-ssmmessages"
  })
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.lab_2a_vpc.id
  service_name        = "com.amazonaws.${local.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpce-logs"
  })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.lab_2a_vpc.id
  service_name        = "com.amazonaws.${local.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpce-secretsmanager"
  })
}

# STS (Interface) - required for aws sts calls from private subnet (no NAT)
resource "aws_vpc_endpoint" "sts" {
  vpc_id              = aws_vpc.lab_2a_vpc.id
  service_name        = "com.amazonaws.${local.region}.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpce-sts"
  })
}

resource "aws_vpc_endpoint" "kms" {
  vpc_id              = aws_vpc.lab_2a_vpc.id
  service_name        = "com.amazonaws.${local.region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${var.project_name}-vpce-kms"
  })
}

# EC2 Instance (private subnet)
resource "aws_instance" "lab_ec2" {
  ami                    = "ami-059f7f172a3ae455b"
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm_profile.name

  user_data = file("/scripts/user_data.sh")

  tags = merge(local.tags, {
    Name = "${var.project_name}-private-ec2"
  })
}

# Target Group
resource "aws_lb_target_group" "tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lab_2a_vpc.id

  health_check {
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 5
    matcher             = "200"
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-tg"
  })
}

resource "aws_lb_target_group_attachment" "tg_attachment" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.lab_ec2.id
  port             = 80
}

# Listeners
resource "aws_lb_listener" "http" {
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

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.lab_2a_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.aws_acm_certificate.tiqs_existing_wildcard.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

# Random Password for Origin Header
resource "random_password" "origin_header_value" {
  length           = 32
  special          = false
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_lb_listener_rule" "require_origin_header" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    http_header {
      http_header_name = var.origin_header_name
      values           = [random_password.origin_header_value.result]
    }
  }
}

# Application Load Balancer
resource "aws_lb" "lab_2a_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id

  dynamic "access_logs" {
    for_each = var.enable_alb_access_logs ? [1] : []
    content {
      bucket  = aws_s3_bucket.alb_logs[0].bucket
      prefix  = var.alb_access_logs_prefix
      enabled = var.enable_alb_access_logs
    }
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-alb"
  })
}

# ALB Access Logs Bucket
resource "aws_s3_bucket" "alb_logs" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = "${var.project_name}-alb-logs-${data.aws_caller_identity.current.account_id}"

  tags = merge(local.tags, {
    Name = "${var.project_name}-alb-logs"
  })
}

resource "aws_s3_bucket_public_access_block" "alb_logs_block" {
  count                   = var.enable_alb_access_logs ? 1 : 0
  bucket                  = aws_s3_bucket.alb_logs[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "alb_logs_ownership" {
  count  = var.enable_alb_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_policy" "alb_logs_policy" {
  bucket = aws_s3_bucket.alb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.alb_logs[0].arn,
          "${aws_s3_bucket.alb_logs[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowELBWriteAccessLogs"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.lab_2a.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/${var.alb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"

        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# WAF (Web Application Firewall)
resource "aws_wafv2_web_acl" "waf" {
  count = var.enable_waf ? 1 : 0

  name  = "${var.project_name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedCommonRules"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CommonRules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}-waf"
    sampled_requests_enabled   = true
  }

  tags = merge(local.tags, {
    Name = "${var.project_name}-waf"
  })
}

# WAF Association and Logging (conditionally created based on enable_waf variable)
resource "aws_wafv2_web_acl_association" "waf_association" {
  count = var.enable_waf ? 1 : 0

  resource_arn = aws_lb.lab_2a_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.waf[0].arn
}

resource "aws_wafv2_web_acl_logging_configuration" "lab_2a_waf_logging" {
  count = (var.enable_waf && var.waf_log_destination == "cloudwatch") ? 1 : 0

  resource_arn = aws_wafv2_web_acl.waf[0].arn
  log_destination_configs = [
    aws_cloudwatch_log_group.lab_2a_waf_log_group[0].arn
  ]

  depends_on = [aws_wafv2_web_acl.waf]
}

# CloudWatch Log Group for WAF
resource "aws_cloudwatch_log_group" "lab_2a_waf_log_group" {
  count             = (var.enable_waf && var.waf_log_destination == "cloudwatch") ? 1 : 0
  name              = "aws-waf-logs-${var.project_name}-web-acl"
  retention_in_days = var.waf_log_retention_days

  tags = merge(local.tags, {
    Name = "${var.project_name}-waf-log-group"
  })
}

# CloudWatch Log Group for application logs (used by watchtower in user_data)
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.project_name}-rds-app"
  retention_in_days = 7

  tags = merge(local.tags, {
    Name = "${var.project_name}-app-log-group"
  })
}

# CloudWatch Metric Filter for DB connection errors
resource "aws_cloudwatch_log_metric_filter" "db_connection_errors" {
  name           = "${local.project_name}-db-connection-errors-filter"
  log_group_name = aws_cloudwatch_log_group.app_logs.name

  pattern = "?\"pymysql.err.OperationalError\" ?\"Can't connect\" ?\"ERROR\" ?\"failed\" ?\"Access denied\""

  metric_transformation {
    name          = "DBConnectionErrors"
    namespace     = "Lab/RDSApp"
    value         = "1"
    default_value = "0"
  }
}

# CloudWatch Alarm for DB connection failures
resource "aws_cloudwatch_metric_alarm" "db_connection_failure" {
  alarm_name          = "${local.project_name}-db-connection-failure"
  alarm_description   = "Triggers when DB connection failures exceed threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "DBConnectionErrors"
  namespace           = "Lab/RDSApp"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.db_incidents.arn]

  tags = merge(local.tags, {
    Name = "${local.project_name}-db-connection-failure-alarm"
  })

  depends_on = [
    aws_cloudwatch_log_metric_filter.db_connection_errors
  ]
}

# CloudWatch Alarm - 500
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.project_name}-alb-5xx"
  alarm_description   = "Triggers when ALB 5XX errors exceed threshold"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 1
  period              = 300
  statistic           = "Sum"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  dimensions = {
    LoadBalancer = aws_lb.lab_2a_alb.arn_suffix
  }
  alarm_actions      = [aws_sns_topic.db_incidents.arn]
  treat_missing_data = "notBreaching"

  tags = merge(local.tags, {
    Name = "${var.project_name}-alb-5xx-alarm"
  })
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "dashboard" {
  dashboard_name = "${var.project_name}-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", aws_lb.lab_2a_alb.arn_suffix],
            [".", "HTTPCode_ELB_5XX_Count", ".", aws_lb.lab_2a_alb.arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = local.region
          title  = "ALB Requests & 5XX Errors"
        }
      }
    ]
  })
}

# RDS Instance (MySQL)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(local.tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

resource "aws_db_instance" "lab_rds" {
  identifier             = "${var.project_name}-mysql"
  engine                 = "mysql"
  engine_version         = "8.4.7"
  instance_class         = var.db_instance_class
  allocated_storage      = var.db_allocated_storage
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  db_name  = local.db_name
  username = local.db_username
  password = random_password.db_password.result

  skip_final_snapshot = true
  publicly_accessible = false

  tags = merge(local.tags, {
    Name = "${var.project_name}-rds"
  })
}

# Generate random password for RDS (or use Secrets Manager directly)
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store RDS credentials in Secrets Manager
resource "aws_secretsmanager_secret" "db_creds" {
  name = local.secret_name
  tags = local.tags
}

resource "aws_secretsmanager_secret_version" "db_creds_version" {
  secret_id = aws_secretsmanager_secret.db_creds.id
  secret_string = jsonencode({
    host     = aws_db_instance.lab_rds.address
    username = aws_db_instance.lab_rds.username
    password = aws_db_instance.lab_rds.password
    dbname   = aws_db_instance.lab_rds.db_name
    port     = 3306
  })
}

# SSM Parameter Store Entries
resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/lab/db/endpoint"
  type  = "SecureString"
  value = aws_db_instance.lab_rds.address

  tags = merge(local.tags, {
    Name = "${local.project_name}-param-db-endpoint"
  })
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/lab/db/port"
  type  = "SecureString"
  value = tostring(aws_db_instance.lab_rds.port)

  tags = merge(local.tags, {
    Name = "${local.project_name}-param-db-port"
  })
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/lab/db/name"
  type  = "SecureString"
  value = local.db_name

  tags = merge(local.tags, {
    Name = "${local.project_name}-param-db-name"
  })
}

# SNS Topic and Subscription for DB incident alerts
resource "aws_sns_topic" "db_incidents" {
  name = "${var.project_name}-db-incidents"

  tags = merge(local.tags, {
    Name = "${var.project_name}-db-incidents-topic"
  })
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol  = "email"
  endpoint  = var.aws_sns_topic_subscription_email_alert_endpoint
}