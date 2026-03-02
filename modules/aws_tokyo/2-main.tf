locals {
  aws_name = "${var.name_prefix}-aws-tokyo"
  tags = {
    Project     = var.name_prefix
    Environment = "lab-4a"
    Compliance  = "PHI-at-rest-Japan-only"
  }
}

# Custom VPC
resource "aws_vpc" "tokyo" {
  cidr_block           = var.aws_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(local.tags, {
    Name = "${local.aws_name}-vpc"
  })
}

# Private subnets (no public subnets in this design)
resource "aws_subnet" "tokyo_private" {
  count             = length(var.aws_private_subnet_cidrs)
  vpc_id            = aws_vpc.tokyo.id
  cidr_block        = var.aws_private_subnet_cidrs[count.index]
  availability_zone = var.aws_azs[count.index]

  tags = merge(local.tags, {
    Name = "${local.aws_name}-private-${count.index + 1}"
  })
}

# Route table for private subnets (no IGW route, only TGW route)
resource "aws_route_table" "tokyo_private" {
  vpc_id = aws_vpc.tokyo.id

  tags = merge(local.tags, {
    Name = "${local.aws_name}-rtb-private"
  })
}

# Associate private subnets with private route table
resource "aws_route_table_association" "tokyo_private" {
  count          = length(aws_subnet.tokyo_private)
  subnet_id      = aws_subnet.tokyo_private[count.index].id
  route_table_id = aws_route_table.tokyo_private.id
}

# Security group for RDS (corridor-only access)
resource "aws_security_group" "tokyo_rds_sg" {
  count       = var.enable_rds ? 1 : 0
  name        = "${var.name_prefix}-tokyo-rds-sg"
  description = "Allow DB access only from corridor CIDRs"
  vpc_id      = aws_vpc.tokyo.id

  # Ingress: DB port only from allowed corridor CIDRs
  dynamic "ingress" {
    for_each = length(var.rds_allowed_cidrs) > 0 ? [1] : []
    content {
      description = "DB from corridor CIDRs only"
      from_port   = var.rds_port
      to_port     = var.rds_port
      protocol    = "tcp"
      cidr_blocks = var.rds_allowed_cidrs
    }
  }

  # Egress: allow outbound (RDS needs to talk to AWS services)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-tokyo-rds-sg"
  })
}

# Tokyo RDS DB Subnet Group and DB Instance (PHI lives here only)
resource "aws_db_subnet_group" "tokyo_rds" {
  count       = var.enable_rds ? 1 : 0
  name        = "${var.name_prefix}-tokyo-rds-subnets"
  description = "Tokyo RDS subnet group (private subnets only)"
  subnet_ids  = aws_subnet.tokyo_private[*].id

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-tokyo-rds-subnet-group"
  })
}

resource "aws_db_instance" "tokyo_rds" {
  allocated_storage         = var.rds_allocated_storage
  count                     = var.enable_rds ? 1 : 0
  db_name                   = var.rds_db_name
  db_subnet_group_name      = aws_db_subnet_group.tokyo_rds[0].name
  engine                    = var.rds_engine
  engine_version            = var.rds_engine_version
  instance_class            = var.rds_instance_class
  identifier                = "${var.name_prefix}-tokyo-rds"
  password                  = var.rds_password
  port                      = var.rds_port
  username                  = var.rds_username
  vpc_security_group_ids    = [aws_security_group.tokyo_rds_sg[0].id]
  publicly_accessible       = false
  storage_encrypted         = true
  multi_az                  = var.rds_multi_az
  backup_retention_period   = var.rds_backup_retention_days
  deletion_protection       = var.rds_deletion_protection
  apply_immediately         = true
  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.name_prefix}-tokyo-rds-final"

  tags = merge(local.tags, {
    Name = "${var.name_prefix}-tokyo-rds"
  })
}

# Transit Gateway (hub)
resource "aws_ec2_transit_gateway" "tokyo" {
  description                     = "Lab4A TGW hub in Tokyo (authoritative)"
  amazon_side_asn                 = var.aws_bgp_asn
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"

  tags = merge(local.tags, {
    Name = "${local.aws_name}-tgw"
  })
}

resource "aws_ec2_transit_gateway_route_table" "tokyo" {
  transit_gateway_id = aws_ec2_transit_gateway.tokyo.id

  tags = merge(local.tags, {
    Name = "${local.aws_name}-tgw-rtb"
  })
}

# Attach VPC to TGW (private subnets)
resource "aws_ec2_transit_gateway_vpc_attachment" "tokyo_vpc" {
  transit_gateway_id = aws_ec2_transit_gateway.tokyo.id
  vpc_id             = aws_vpc.tokyo.id
  subnet_ids         = [for s in aws_subnet.tokyo_private : s.id]

  tags = merge(local.tags, {
    Name = "${local.aws_name}-tgw-vpc-attach"
  })
}

resource "aws_ec2_transit_gateway_route_table_association" "tokyo_vpc_assoc" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tokyo_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tokyo.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "tokyo_vpc_prop" {
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.tokyo_vpc.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.tokyo.id
}

# VPC return routing toward branch CIDR via TGW (auditable/explicit)
resource "aws_route" "tokyo_private_to_gcp" {
  route_table_id         = aws_route_table.tokyo_private.id
  destination_cidr_block = var.gcp_branch_cidr
  transit_gateway_id     = aws_ec2_transit_gateway.tokyo.id
}