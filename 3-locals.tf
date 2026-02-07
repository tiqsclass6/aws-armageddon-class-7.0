locals {
  name_prefix     = var.name_prefix
  route53_zone_id = data.aws_route53_zone.main.zone_id

  public_subnets = {
    for idx, cidr in var.public_subnet_cidrs : idx => {
      cidr_block        = cidr
      availability_zone = "${var.aws_region}${var.az_suffixes[idx]}"
      name              = "${local.name_prefix}-public-${var.az_suffixes[idx]}"
    }
  }

  private_subnets = {
    for idx, cidr in var.private_subnet_cidrs : idx => {
      cidr_block        = cidr
      availability_zone = "${var.aws_region}${var.az_suffixes[idx]}"
      name              = "${local.name_prefix}-private-${var.az_suffixes[idx]}"
    }
  }
}