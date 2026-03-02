# VPN Gateway (Highly Available)
resource "google_compute_ha_vpn_gateway" "nihonmachi_ha_vpn" {
  name    = "${var.name_prefix}-ha-vpn"
  region  = var.gcp_region
  network = google_compute_network.nihonmachi_vpc.id
}

# NCC Hub (for spoke attachment)
resource "google_network_connectivity_hub" "nihonmachi_hub" {
  name = "${var.name_prefix}-hub"
}

# NCC Spoke: Attach VPN tunnels to NCC Hub
resource "google_network_connectivity_spoke" "nihonmachi_spoke_vpn" {
  count    = var.enable_gcp_vpn ? 1 : 0
  name     = "${var.name_prefix}-spoke-vpn"
  hub      = google_network_connectivity_hub.nihonmachi_hub.id
  location = var.gcp_region

  linked_vpn_tunnels {
    uris = [
      google_compute_vpn_tunnel.nihonmachi_tunnel1[0].id,
      google_compute_vpn_tunnel.nihonmachi_tunnel2[0].id
    ]

    site_to_site_data_transfer = true
  }
}

# Phase 2: External VPN Gateway representing AWS side
resource "google_compute_external_vpn_gateway" "nihonmachi_aws_ext_gw" {
  count           = var.enable_gcp_vpn ? 1 : 0
  name            = "${var.name_prefix}-aws-ext-gw"
  redundancy_type = "TWO_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = var.aws_vpn_tunnel1_outside_ip
  }

  interface {
    id         = 1
    ip_address = var.aws_vpn_tunnel2_outside_ip
  }
}

# Tunnel 1: IKEv2, AES256, SHA256, DH15
resource "google_compute_vpn_tunnel" "nihonmachi_tunnel1" {
  count                           = var.enable_gcp_vpn ? 1 : 0
  name                            = "${var.name_prefix}-tunnel1"
  description                     = "Tunnel 1: IKEv2, AES256, SHA256, DH15"
  region                          = var.gcp_region
  vpn_gateway                     = google_compute_ha_vpn_gateway.nihonmachi_ha_vpn.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.nihonmachi_aws_ext_gw[0].id
  peer_external_gateway_interface = 0
  shared_secret                   = var.tunnel1_psk
  router                          = google_compute_router.nihonmachi_router.id
  ike_version                     = 2
}

# Tunnel 2: IKEv2, AES256, SHA256, DH16
resource "google_compute_vpn_tunnel" "nihonmachi_tunnel2" {
  count                           = var.enable_gcp_vpn ? 1 : 0
  name                            = "${var.name_prefix}-tunnel2"
  description                     = "Tunnel 2: IKEv2, AES256, SHA256, DH16"
  region                          = var.gcp_region
  vpn_gateway                     = google_compute_ha_vpn_gateway.nihonmachi_ha_vpn.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.nihonmachi_aws_ext_gw[0].id
  peer_external_gateway_interface = 1
  shared_secret                   = var.tunnel2_psk
  router                          = google_compute_router.nihonmachi_router.id
  ike_version                     = 2
}

# Router Interface 1: Links Tunnel 1 to Router
resource "google_compute_router_interface" "nihonmachi_if1" {
  count      = var.enable_gcp_vpn ? 1 : 0
  name       = "${var.name_prefix}-if1"
  region     = var.gcp_region
  router     = google_compute_router.nihonmachi_router.name
  ip_range   = var.bgp_link_local.gcp_iface1_range
  vpn_tunnel = google_compute_vpn_tunnel.nihonmachi_tunnel1[0].name
}

# Router Interface 2: Links Tunnel 2 to Router
resource "google_compute_router_interface" "nihonmachi_if2" {
  count      = var.enable_gcp_vpn ? 1 : 0
  name       = "${var.name_prefix}-if2"
  region     = var.gcp_region
  router     = google_compute_router.nihonmachi_router.name
  ip_range   = var.bgp_link_local.gcp_iface2_range
  vpn_tunnel = google_compute_vpn_tunnel.nihonmachi_tunnel2[0].name
}

# BGP Peer 1: Links Router to Tunnel 1
resource "google_compute_router_peer" "nihonmachi_peer1" {
  count                     = var.enable_gcp_vpn ? 1 : 0
  name                      = "${var.name_prefix}-peer1"
  region                    = var.gcp_region
  router                    = google_compute_router.nihonmachi_router.name
  interface                 = google_compute_router_interface.nihonmachi_if1[0].name
  peer_ip_address           = var.bgp_link_local.gcp_peer1_ip
  peer_asn                  = var.aws_bgp_asn
  advertised_route_priority = 100
}

# BGP Peer 2: Links Router to Tunnel 2
resource "google_compute_router_peer" "nihonmachi_peer2" {
  count                     = var.enable_gcp_vpn ? 1 : 0
  name                      = "${var.name_prefix}-peer2"
  region                    = var.gcp_region
  router                    = google_compute_router.nihonmachi_router.name
  interface                 = google_compute_router_interface.nihonmachi_if2[0].name
  peer_ip_address           = var.bgp_link_local.gcp_peer2_ip
  peer_asn                  = var.aws_bgp_asn
  advertised_route_priority = 100
}