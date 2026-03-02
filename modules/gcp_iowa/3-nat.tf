# Nihonmachi VPC Router
resource "google_compute_router" "nihonmachi_router" {
  name    = "nihonmachi-router"
  region  = var.gcp_region
  network = google_compute_network.nihonmachi_vpc.id

  bgp {
    asn            = var.gcp_bgp_asn
    advertise_mode = "CUSTOM"

    # Advertise ONLY the branch subnet CIDR
    advertised_ip_ranges {
      range = var.nihonmachi_subnet_cidr
    }
  }
}

# Nihonmachi VPC NAT (for spoke VM egress)
resource "google_compute_router_nat" "nihonmachi_nat" {
  count                              = var.enable_nat ? 1 : 0
  name                               = "nihonmachi-nat"
  router                             = google_compute_router.nihonmachi_router.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}