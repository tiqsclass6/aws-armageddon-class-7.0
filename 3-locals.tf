locals {
  name_prefix = var.name_prefix

  az_map = {
    for idx, az in data.aws_availability_zones.available.names :
    az => {
      cidr = cidrsubnet(var.vpc_cidr, 4, idx)
      name = "${local.name_prefix}-${var.az_suffixes[idx % length(var.az_suffixes)]}"
    }
  }
}
