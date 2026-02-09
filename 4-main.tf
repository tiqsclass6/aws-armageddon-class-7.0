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

# Public Subnets (2 AZs)
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

# Private Subnets (2 AZs)
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

# NAT Gateway + EIP
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-nat-eip" }
  )
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-nat" }
  )

  depends_on = [aws_internet_gateway.igw]
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

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

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
  description = "Security group for lab EC2 instance"
  vpc_id      = aws_vpc.lab-1c-vpc.id

  dynamic "ingress" {
    for_each = [
      {
        port        = 80
        description = "HTTP from anywhere"
        cidr        = ["0.0.0.0/0"]
      },
      {
        port        = 22
        description = "SSH from my current IP only"
        cidr        = [local.my_ip_cidr]
      }
    ]

    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
      cidr_blocks = ingress.value.cidr
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-ec2-sg" }
  )
}

resource "aws_security_group" "rds_sg" {
  name        = "${local.project_name}-rds-sg"
  description = "Security group for lab RDS instance"
  vpc_id      = aws_vpc.lab-1c-vpc.id

  ingress {
    description     = "MySQL from EC2 SG"
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

# IAM Role and Policies
resource "aws_iam_role" "ec2_role" {
  name = "${local.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { Service = "ec2.amazonaws.com" }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy" "secrets_policy" {
  name = "${local.project_name}-secrets-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadSpecificSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.db_creds.arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "ssm_policy" {
  name = "${local.project_name}-ssm-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = "arn:aws:ssm:${local.region}:${data.aws_caller_identity.current.account_id}:parameter/lab/db/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_policy" {
  name = "${local.project_name}-cloudwatch-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
        ]
        Resource = "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/${local.project_name}-rds-app:*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${local.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "lab_ec2" {
  ami                         = data.aws_ssm_parameter.al2023_ami.value
  instance_type               = local.instance_type
  key_name                    = var.aws_key_pair_name
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  user_data = file("./scripts/user_data.sh")

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-ec2-app" }
  )
}

# RDS, Secrets, SSM
resource "random_password" "db_password" {
  length  = 16
  special = false
}

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
  name        = "/lab/db/endpoint"
  description = "RDS database endpoint for lab application"
  type        = "SecureString"
  value       = aws_db_instance.lab_rds.address

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-param-db-endpoint" }
  )
}

resource "aws_ssm_parameter" "db_port" {
  name        = "/lab/db/port"
  description = "RDS database port for lab application"
  type        = "SecureString"
  value       = tostring(aws_db_instance.lab_rds.port)

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-param-db-port" }
  )
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/lab/db/name"
  description = "RDS database name for lab application"
  type        = "SecureString"
  value       = local.db_name

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-param-db-name" }
  )
}

# RDS DB Instance
resource "aws_db_subnet_group" "lab_rds" {
  name       = "${local.project_name}-rds-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-rds-subnet-group" }
  )
}

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
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false

  tags = merge(
    local.tags,
    { Name = "${local.project_name}-mysql" }
  )
}

# CloudWatch + SNS
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${local.project_name}-rds-app"
  retention_in_days = 7
  tags              = local.tags
}

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

resource "aws_cloudwatch_metric_alarm" "db_connection_failure" {
  alarm_name        = "${local.project_name}-db-connection-failure"
  alarm_description = "Triggers when the number of database connection failures exceeds 3 within a 5-minute period. Indicates potential issues with RDS connectivity, credential validity, network reachability, or database availability. Used for early detection of application outages in the EC2 → RDS Notes App."

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
    aws_cloudwatch_log_metric_filter.db_connection_errors,
    aws_sns_topic.db_incidents
  ]
}

resource "aws_sns_topic" "db_incidents" {
  name = "${local.project_name}-db-incidents-v1"
  tags = local.tags
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.db_incidents.arn
  protocol  = "email"
  endpoint  = var.aws_sns_topic_subscription_email_alert_endpoint
}