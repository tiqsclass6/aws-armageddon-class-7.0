# Customer Gateway 1: Represents the GCP VPN gateway interface 0
resource "aws_customer_gateway" "gcp_cgw0" {
  bgp_asn    = var.gcp_bgp_asn
  ip_address = var.gcp_ha_vpn_interface0_ip
  type       = "ipsec.1"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name_prefix}-gcp-cgw0"
  }
}

# Customer Gateway 2: Represents the GCP VPN gateway interface 1
resource "aws_customer_gateway" "gcp_cgw1" {
  bgp_asn    = var.gcp_bgp_asn
  ip_address = var.gcp_ha_vpn_interface1_ip
  type       = "ipsec.1"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name_prefix}-gcp-cgw1"
  }
}

# VPN Connection from AWS TGW to GCP CGW
resource "aws_vpn_connection" "tgw_aws_to_gcp" {
  transit_gateway_id  = var.aws_tgw_id
  customer_gateway_id = aws_customer_gateway.gcp_cgw0.id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_inside_cidr                  = var.bgp_link_local.aws_tunnel1_inside_cidr
  tunnel1_preshared_key                = var.tunnel1_psk
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [15]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [15]

  tunnel2_inside_cidr                  = var.bgp_link_local.aws_tunnel2_inside_cidr
  tunnel2_preshared_key                = var.tunnel2_psk
  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [16]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [16]

  tags = {
    Name = "${var.name_prefix}-tgw-vpn-to-gcp"
  }
}

# Transit Gateway Route Table Association: Associate the VPN connection with the TGW route table
resource "aws_ec2_transit_gateway_route_table_association" "vpn_assoc" {
  transit_gateway_attachment_id  = aws_vpn_connection.tgw_aws_to_gcp.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.aws_tgw_route_table_id
}

# Transit Gateway Route Table Propagation: Propagate routes from VPN connection to TGW route table
resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_prop" {
  transit_gateway_attachment_id  = aws_vpn_connection.tgw_aws_to_gcp.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.aws_tgw_route_table_id
}