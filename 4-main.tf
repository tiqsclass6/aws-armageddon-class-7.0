module "aws_tokyo" {
  source = "./modules/aws_tokyo"

  aws_vpc_cidr      = var.aws_vpc_cidr
  aws_bgp_asn       = var.aws_bgp_asn
  gcp_branch_cidr   = var.nihonmachi_subnet_cidr
  name_prefix       = var.name_prefix
  rds_password      = var.tokyo_rds_password
  rds_allowed_cidrs = [var.nihonmachi_subnet_cidr]
}

module "gcp_iowa" {
  source = "./modules/gcp_iowa"

  allowed_vpn_cidrs            = var.allowed_vpn_cidrs
  aws_bgp_asn                  = var.aws_bgp_asn
  aws_vpc_cidr                 = var.aws_vpc_cidr
  aws_vpn_tunnel1_outside_ip   = var.enable_gcp_vpn ? module.vpn.aws_tunnel1_outside_ip : ""
  aws_vpn_tunnel2_outside_ip   = var.enable_gcp_vpn ? module.vpn.aws_tunnel2_outside_ip : ""
  bgp_link_local               = local.bgp_link_local
  db_password_secret_name      = var.db_password_secret_name
  enable_gcp_vpn               = var.enable_gcp_vpn
  gcp_project_id               = var.gcp_project_id
  gcp_region                   = var.gcp_region
  gcp_zone                     = var.gcp_zone
  gcp_bgp_asn                  = var.gcp_bgp_asn
  name_prefix                  = var.name_prefix
  nihonmachi_subnet_cidr       = var.nihonmachi_subnet_cidr
  nihonmachi_proxy_subnet_cidr = var.nihonmachi_proxy_subnet_cidr
  tunnel1_psk                  = var.tunnel1_psk
  tunnel2_psk                  = var.tunnel2_psk
}

module "vpn" {
  source = "./modules/vpn"

  aws_tgw_id               = module.aws_tokyo.tgw_id
  aws_tgw_route_table_id   = module.aws_tokyo.tgw_route_table_id
  aws_bgp_asn              = var.aws_bgp_asn
  bgp_link_local           = local.bgp_link_local
  gcp_bgp_asn              = var.gcp_bgp_asn
  gcp_ha_vpn_interface0_ip = module.gcp_iowa.ha_vpn_interface0_ip
  gcp_ha_vpn_interface1_ip = module.gcp_iowa.ha_vpn_interface1_ip
  name_prefix              = var.name_prefix
  tunnel1_psk              = var.tunnel1_psk
  tunnel2_psk              = var.tunnel2_psk
}