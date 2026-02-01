# VPC
resource "aws_vpc" "shinjuku" {
  provider             = aws.shinjuku
  cidr_block           = var.shinjuku_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-vpc"
  })
}

# Public subnets (2 AZs)
resource "aws_subnet" "shinjuku_public" {
  provider                = aws.shinjuku
  count                   = 2
  vpc_id                  = aws_vpc.shinjuku.id
  cidr_block              = cidrsubnet(var.shinjuku_vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.shinjuku.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-public-subnet-${count.index + 1}"
    Tier = "public"
  })
}

# Private subnets (2 AZs)
resource "aws_subnet" "shinjuku_private" {
  provider          = aws.shinjuku
  count             = 2
  vpc_id            = aws_vpc.shinjuku.id
  cidr_block        = cidrsubnet(var.shinjuku_vpc_cidr, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.shinjuku.names[count.index]

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-private-subnet-${count.index + 1}"
    Tier = "private"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "shinjuku" {
  provider = aws.shinjuku
  vpc_id   = aws_vpc.shinjuku.id

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-igw"
  })
}

# Elastic IP for NAT Gateway
resource "aws_eip" "shinjuku_eip" {
  provider = aws.shinjuku
  domain   = "vpc"

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-eip"
  })
}

# NAT Gateway
resource "aws_nat_gateway" "shinjuku_nat" {
  provider      = aws.shinjuku
  allocation_id = aws_eip.shinjuku_eip.id
  subnet_id     = aws_subnet.shinjuku_public[0].id

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-nat"
  })

  depends_on = [aws_internet_gateway.shinjuku]
}

# Route tables and Routes
resource "aws_route_table" "shinjuku_public" {
  provider = aws.shinjuku
  vpc_id   = aws_vpc.shinjuku.id

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-public-rt"
  })
}

resource "aws_route" "shinjuku_public" {
  provider               = aws.shinjuku
  route_table_id         = aws_route_table.shinjuku_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.shinjuku.id
}

resource "aws_route_table" "shinjuku_private" {
  provider = aws.shinjuku
  vpc_id   = aws_vpc.shinjuku.id

  tags = merge(local.tags, {
    Name = "${var.shinjuku_private_route_table_name_prefix}-main"
  })
}

resource "aws_route" "shinjuku_private" {
  provider               = aws.shinjuku
  route_table_id         = aws_route_table.shinjuku_private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.shinjuku_nat.id
}

# Route table associations
resource "aws_route_table_association" "shinjuku_public_a" {
  provider       = aws.shinjuku
  subnet_id      = aws_subnet.shinjuku_public[0].id
  route_table_id = aws_route_table.shinjuku_public.id
}

resource "aws_route_table_association" "shinjuku_public_b" {
  provider       = aws.shinjuku
  subnet_id      = aws_subnet.shinjuku_public[1].id
  route_table_id = aws_route_table.shinjuku_public.id
}

resource "aws_route_table_association" "shinjuku_private_a" {
  provider       = aws.shinjuku
  subnet_id      = aws_subnet.shinjuku_private[0].id
  route_table_id = aws_route_table.shinjuku_private.id
}

resource "aws_route_table_association" "shinjuku_private_b" {
  provider       = aws.shinjuku
  subnet_id      = aws_subnet.shinjuku_private[1].id
  route_table_id = aws_route_table.shinjuku_private.id
}

# Security Group for VPC Endpoints
resource "aws_security_group" "shinjuku_vpce_sg" {
  provider    = aws.shinjuku
  name        = "${local.shinjuku_prefix}-vpce-sg"
  description = "Allow instances in Shinjuku VPC to reach interface endpoints over 443"
  vpc_id      = aws_vpc.shinjuku.id

  ingress {
    description = "HTTPS from Shinjuku VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.shinjuku_vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-vpce-sg"
  })
}

# Security Group for RDS
resource "aws_security_group" "shinjuku_rds_sg" {
  provider    = aws.shinjuku
  name        = "${local.shinjuku_prefix}-rds-sg"
  description = "Shinjuku RDS SG (Shinjuku only)"
  vpc_id      = aws_vpc.shinjuku.id

  ingress {
    description = "MySQL from Liberdade VPC over TGW"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [local.liberdade_vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = var.shinjuku_rds_sg_name
  })
}

# Security Group for Route53 Resolver
resource "aws_security_group" "shinjuku_resolver_sg" {
  provider    = aws.shinjuku
  name        = "${local.shinjuku_prefix}-resolver-sg"
  description = "Allow DNS queries from Liberdade VPC"
  vpc_id      = aws_vpc.shinjuku.id

  ingress {
    description = "DNS from Liberdade VPC"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [local.liberdade_vpc_cidr]
  }

  ingress {
    description = "DNS from Liberdade VPC"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [local.liberdade_vpc_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.shinjuku_prefix}-resolver-sg"
  })
}

# VPC Endpoints
resource "aws_vpc_endpoint" "shinjuku_ssm" {
  provider            = aws.shinjuku
  vpc_id              = aws_vpc.shinjuku.id
  service_name        = "com.amazonaws.ap-northeast-1.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.shinjuku_private[0].id, aws_subnet.shinjuku_private[1].id]
  security_group_ids  = [aws_security_group.shinjuku_vpce_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "shinjuku_ssmmessages" {
  provider            = aws.shinjuku
  vpc_id              = aws_vpc.shinjuku.id
  service_name        = "com.amazonaws.ap-northeast-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.shinjuku_private[0].id, aws_subnet.shinjuku_private[1].id]
  security_group_ids  = [aws_security_group.shinjuku_vpce_sg.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "shinjuku_ec2messages" {
  provider            = aws.shinjuku
  vpc_id              = aws_vpc.shinjuku.id
  service_name        = "com.amazonaws.ap-northeast-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.shinjuku_private[0].id, aws_subnet.shinjuku_private[1].id]
  security_group_ids  = [aws_security_group.shinjuku_vpce_sg.id]
  private_dns_enabled = true
}