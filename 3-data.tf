data "aws_availability_zones" "liberdade" {
  provider = aws.liberdade
}

data "aws_ami" "al2023_liberdade" {
  provider    = aws.liberdade
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_availability_zones" "shinjuku" {
  provider = aws.shinjuku
  state    = "available"
}

data "aws_ec2_managed_prefix_list" "cloudfront" {
  provider = aws.liberdade
  name     = "com.amazonaws.global.cloudfront.origin-facing"
}

data "aws_subnets" "shinjuku_private" {
  provider = aws.shinjuku

  filter {
    name   = "vpc-id"
    values = [aws_vpc.shinjuku.id]
  }

  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
}