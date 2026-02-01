data "aws_caller_identity" "current" {}

# VPC
resource "aws_vpc" "liberdade" {
  provider             = aws.liberdade
  cidr_block           = local.liberdade_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-vpc"
  })
}

# Public Subnets (2 AZs)
resource "aws_subnet" "liberdade_public" {
  count                   = 2
  provider                = aws.liberdade
  vpc_id                  = aws_vpc.liberdade.id
  cidr_block              = cidrsubnet(local.liberdade_vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.liberdade.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-public-subnet-${count.index + 1}"
  })
}

# Private Subnets (2 AZs)
resource "aws_subnet" "liberdade_private" {
  count                   = 2
  provider                = aws.liberdade
  vpc_id                  = aws_vpc.liberdade.id
  cidr_block              = cidrsubnet(local.liberdade_vpc_cidr, 8, count.index + 2)
  availability_zone       = data.aws_availability_zones.liberdade.names[count.index]
  map_public_ip_on_launch = false

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-private-subnet-${count.index + 1}"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "liberdade" {
  provider = aws.liberdade
  vpc_id   = aws_vpc.liberdade.id
  tags     = merge(local.tags, { Name = "${local.liberdade_prefix}-igw" })
}

# Elastic IP
resource "aws_eip" "liberdade_eip" {
  provider = aws.liberdade
  domain   = "vpc"
  tags     = merge(local.tags, { Name = "${local.liberdade_prefix}-eip" })
}

# NAT Gateway
resource "aws_nat_gateway" "liberdade_nat" {
  provider      = aws.liberdade
  allocation_id = aws_eip.liberdade_eip.id
  subnet_id     = aws_subnet.liberdade_public[0].id
  tags          = merge(local.tags, { Name = "${local.liberdade_prefix}-nat" })
  depends_on    = [aws_internet_gateway.liberdade]
}

# Route Tables and Routes
resource "aws_route_table" "liberdade_public" {
  provider = aws.liberdade
  vpc_id   = aws_vpc.liberdade.id

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-public-rt"
  })

  depends_on = [aws_internet_gateway.liberdade]
}

resource "aws_route" "liberdade_public" {
  provider               = aws.liberdade
  route_table_id         = aws_route_table.liberdade_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.liberdade.id
}

resource "aws_route_table" "liberdade_private" {
  provider = aws.liberdade
  vpc_id   = aws_vpc.liberdade.id

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-private-rt"
  })
}

resource "aws_route" "liberdade_private_default" {
  provider               = aws.liberdade
  route_table_id         = aws_route_table.liberdade_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.liberdade_nat.id
}

# Route Table Associations
resource "aws_route_table_association" "liberdade_public_subnet_a" {
  provider       = aws.liberdade
  subnet_id      = aws_subnet.liberdade_public[0].id
  route_table_id = aws_route_table.liberdade_public.id
}

resource "aws_route_table_association" "liberdade_public_subnet_b" {
  provider       = aws.liberdade
  subnet_id      = aws_subnet.liberdade_public[1].id
  route_table_id = aws_route_table.liberdade_public.id
}

resource "aws_route_table_association" "liberdade_private_subnet_a" {
  provider       = aws.liberdade
  subnet_id      = aws_subnet.liberdade_private[0].id
  route_table_id = aws_route_table.liberdade_private.id
}

resource "aws_route_table_association" "liberdade_private_subnet_b" {
  provider       = aws.liberdade
  subnet_id      = aws_subnet.liberdade_private[1].id
  route_table_id = aws_route_table.liberdade_private.id
}

# Security Group for ALB
resource "aws_security_group" "liberdade_alb_sg" {
  provider    = aws.liberdade
  name        = "${local.liberdade_prefix}-alb-sg"
  description = "ALB SG for Liberdade"
  vpc_id      = aws_vpc.liberdade.id

  ingress {
    description     = "HTTP from CloudFront only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-alb-sg"
  })
}

# Security Group for EC2 App Instances
resource "aws_security_group" "liberdade_app_sg" {
  provider    = aws.liberdade
  name        = "${local.liberdade_prefix}-app-sg"
  description = "App instances SG for Liberdade"
  vpc_id      = aws_vpc.liberdade.id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.liberdade_alb_sg.id]
  }

  egress {
    description = "All outbound (DB egress controlled by routing + Shinjuku SG)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-app-sg"
  })
}

# Security Group for VPC Endpoints
resource "aws_security_group" "liberdade_vpce_sg" {
  provider    = aws.liberdade
  name        = "${local.liberdade_prefix}-vpce-sg"
  description = "Allow instances in Liberdade VPC to reach interface endpoints over 443"
  vpc_id      = aws_vpc.liberdade.id

  ingress {
    description     = "HTTPS from app instances"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.liberdade_app_sg.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-vpce-sg"
  })
}

# VPC Endpoints
resource "aws_vpc_endpoint" "ssm" {
  provider            = aws.liberdade
  vpc_id              = aws_vpc.liberdade.id
  service_name        = "com.amazonaws.sa-east-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.liberdade_private[0].id, aws_subnet.liberdade_private[1].id]
  security_group_ids  = [aws_security_group.liberdade_vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-ssm-vpce"
  })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  provider            = aws.liberdade
  vpc_id              = aws_vpc.liberdade.id
  service_name        = "com.amazonaws.sa-east-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.liberdade_private[0].id, aws_subnet.liberdade_private[1].id]
  security_group_ids  = [aws_security_group.liberdade_vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-ssmmessages-vpce"
  })
}

resource "aws_vpc_endpoint" "ec2messages" {
  provider            = aws.liberdade
  vpc_id              = aws_vpc.liberdade.id
  service_name        = "com.amazonaws.sa-east-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.liberdade_private[0].id, aws_subnet.liberdade_private[1].id]
  security_group_ids  = [aws_security_group.liberdade_vpce_sg.id]
  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${local.liberdade_prefix}-ec2messages-vpce"
  })
}