# Custom VPC
resource "aws_vpc" "lab-1c-vpc" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.tags,
    { Name = "${var.project_name}-vpc" }
  )
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.lab-1c-vpc.id
  cidr_block              = cidrsubnet(local.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    local.tags,
    { Name = "${var.project_name}-public-subnet-${count.index + 1}" }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.lab-1c-vpc.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = merge(
    local.tags,
    { Name = "${var.project_name}-private-subnet-${count.index + 1}" }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lab-1c-vpc.id

  tags = merge(
    local.tags,
    { Name = "${var.project_name}-igw" }
  )
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab-1c-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    local.tags,
    { Name = "${var.project_name}-public-rt" }
  )
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.lab-1c-vpc.id

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-private-rt" }
  )
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "ec2_sg" {
  name        = "${local.project_name}-ec2-sg"
  description = "Security group for private lab EC2 instance"
  vpc_id      = aws_vpc.lab-1c-vpc.id

  ingress {
    description = "HTTP from anywhere (for app access / future ALB)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-ec2-sg-private" }
  )
}

resource "aws_security_group" "rds_sg" {
  name        = "${local.project_name}-rds-sg"
  description = "Security group for lab RDS instance"
  vpc_id      = aws_vpc.lab-1c-vpc.id

  ingress {
    description     = "MySQL from EC2 security group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-rds-sg" }
  )
}

resource "aws_security_group" "vpce_sg" {
  name        = "${local.project_name}-vpce-sg"
  description = "Security group for VPC endpoints"
  vpc_id      = aws_vpc.lab-1c-vpc.id

  ingress {
    description     = "HTTPS from EC2 instances"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role & Instance Profile for EC2
resource "aws_iam_role" "ec2_role" {
  name = "${local.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "secrets_specific" {
  name = "${local.project_name}-secrets-specific"
  role = aws_iam_role.ec2_role.id

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

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "ssm_labdb_only" {
  name = "${local.project_name}-ssm-labdb-only"
  role = aws_iam_role.ec2_role.id

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

resource "aws_iam_role_policy" "cloudwatch_logs_tight" {
  name = "${local.project_name}-cwlogs-tight"
  role = aws_iam_role.ec2_role.id

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

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 Instance - Private subnet
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "lab_ec2" {
  ami                    = "ami-090a0f9ead345db4e"
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = false

  user_data = file("./scripts/user_data.sh")

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-ec2-app-private" }
  )
}

# Random password for RDS
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Secrets Manager - Database credentials
resource "aws_secretsmanager_secret" "db_creds" {
  name        = local.secret_name
  description = "RDS credentials for lab-1c application"
  tags        = local.tags
}

resource "aws_secretsmanager_secret_version" "db_creds_version" {
  secret_id = aws_secretsmanager_secret.db_creds.id
  secret_string = jsonencode({
    username = local.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.lab_rds.address
    port     = 3306
    dbname   = local.db_name
  })
}

# SSM Parameter Store Entries
resource "aws_ssm_parameter" "db_endpoint" {
  name  = "/lab/db/endpoint"
  type  = "String"
  value = aws_db_instance.lab_rds.address

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-param-db-endpoint" }
  )
}

resource "aws_ssm_parameter" "db_port" {
  name  = "/lab/db/port"
  type  = "String"
  value = tostring(aws_db_instance.lab_rds.port)

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-param-db-port" }
  )
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/lab/db/name"
  type  = "String"
  value = local.db_name

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-param-db-name" }
  )
}

# RDS Subnet Group
resource "aws_db_subnet_group" "lab_rds" {
  name       = "${local.project_name}-rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-rds-subnet-group" }
  )
}

# RDS Instance
resource "aws_db_instance" "lab_rds" {
  identifier             = "${local.project_name}-mysql"
  engine                 = "mysql"
  engine_version         = "8.4"
  instance_class         = local.db_instance_class
  allocated_storage      = 20
  username               = local.db_username
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.lab_rds.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true
  multi_az            = false

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-mysql" }
  )
}

# CloudWatch Log Group for application logs
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${local.project_name}-rds-app"
  retention_in_days = 7
  tags              = local.tags
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

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-db-connection-failure-alarm" }
  )

  depends_on = [
    aws_cloudwatch_log_metric_filter.db_connection_errors
  ]
}

# SNS Topic for incidents
resource "aws_sns_topic" "db_incidents" {
  name = "${local.project_name}-db-incidents"
  tags = local.tags
}

# SNS Email Subscription (optional but useful for lab)
resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol  = "email"
  endpoint  = var.aws_sns_topic_subscription_email_alert_endpoint
}

# VPC Endpoints - Interface Endpoints
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.lab-1c-vpc.id
  service_name        = "com.amazonaws.${local.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, { Name = "${local.project_name}-vpce-ssm" })
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.lab-1c-vpc.id
  service_name        = "com.amazonaws.${local.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, { Name = "${local.project_name}-vpce-ec2messages" })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.lab-1c-vpc.id
  service_name        = "com.amazonaws.${local.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, { Name = "${local.project_name}-vpce-ssmmessages" })
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.lab-1c-vpc.id
  service_name        = "com.amazonaws.${local.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, { Name = "${local.project_name}-vpce-logs" })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.lab-1c-vpc.id
  service_name        = "com.amazonaws.${local.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, { Name = "${local.project_name}-vpce-secretsmanager" })
}

resource "aws_vpc_endpoint" "kms" {
  count               = 1
  vpc_id              = aws_vpc.lab-1c-vpc.id
  service_name        = "com.amazonaws.${local.region}.kms"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, { Name = "${local.project_name}-vpce-kms" })
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.lab-1c-vpc.id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private.id]

  tags = merge(local.tags, { Name = "${local.project_name}-vpce-s3-gateway" })
}