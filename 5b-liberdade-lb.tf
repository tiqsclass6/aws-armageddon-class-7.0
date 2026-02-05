# Application Load Balancer
resource "aws_lb" "liberdade_alb" {
  provider           = aws.liberdade
  name               = "${local.liberdade_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.liberdade_alb_sg.id]
  subnets            = [aws_subnet.liberdade_public[0].id, aws_subnet.liberdade_public[1].id]

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-alb"
  })
}

# Target Group
resource "aws_lb_target_group" "liberdade_tg" {
  provider = aws.liberdade
  name     = "${local.liberdade_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.liberdade.id

  health_check {
    enabled             = true
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = "/health"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-tg"
  })
}

# HTTP Listener
resource "aws_lb_listener" "liberdade_http_listener" {
  provider          = aws.liberdade
  load_balancer_arn = aws_lb.liberdade_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Forbidden"
      status_code  = "403"
    }
  }
}

# Listener Rule CloudFront Header Allow
resource "aws_lb_listener_rule" "liberdade_allow_cloudfront_header" {
  provider     = aws.liberdade
  listener_arn = aws_lb_listener.liberdade_http_listener.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.liberdade_tg.arn
  }

  condition {
    http_header {
      http_header_name = lower(var.origin_header_name)
      values           = [random_password.origin_header_value.result]
    }
  }
}

# Launch Template
resource "aws_launch_template" "liberdade_lt" {
  provider               = aws.liberdade
  name_prefix            = "${local.liberdade_prefix}-lt-"
  image_id               = data.aws_ami.al2023_liberdade.id
  instance_type          = var.instance_type
  update_default_version = true

  vpc_security_group_ids = [aws_security_group.liberdade_app_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.liberdade_ec2_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/scripts/lab-3b.sh.tftpl", {
    app_region        = "sa-east-1"
    secret_region     = "ap-northeast-1"
    secret_id         = "lab-3b/shinjuku/rds/mysql_v13"
    cloudfront_domain = local.cloudfront_domain
    log_group         = "/aws/ec2/lab-3b-shinjuku-rds-app"
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags, {
      Name             = "${local.liberdade_prefix}-app"
      CloudFrontDistId = aws_cloudfront_distribution.liberdade_cf.id
    })
  }

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-lt"
  })
}

# Auto Scaling Group
resource "aws_autoscaling_group" "liberdade_asg" {
  provider            = aws.liberdade
  name                = "${local.liberdade_prefix}-asg"
  desired_capacity    = var.asg_desired
  min_size            = var.asg_min
  max_size            = var.asg_max
  vpc_zone_identifier = [aws_subnet.liberdade_private[0].id, aws_subnet.liberdade_private[1].id]
  target_group_arns   = [aws_lb_target_group.liberdade_tg.arn]
  health_check_type   = "ELB"

  launch_template {
    id      = aws_launch_template.liberdade_lt.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
    }
  }

  tag {
    key                 = "Name"
    value               = "${local.liberdade_prefix}-asg"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}