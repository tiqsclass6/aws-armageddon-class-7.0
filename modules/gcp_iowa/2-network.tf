resource "google_compute_network" "nihonmachi_vpc" {
  name                    = "nihonmachi-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "nihonmachi_private_subnet" {
  name                     = "nihonmachi-subnet"
  region                   = var.gcp_region
  network                  = google_compute_network.nihonmachi_vpc.id
  ip_cidr_range            = var.nihonmachi_subnet_cidr
  private_ip_google_access = true
}

# REQUIRED for INTERNAL_MANAGED load balancer: proxy-only subnet
resource "google_compute_subnetwork" "nihonmachi_proxy_subnet" {
  name          = "nihonmachi-proxy-subnet"
  ip_cidr_range = var.nihonmachi_proxy_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.nihonmachi_vpc.id

  purpose = "REGIONAL_MANAGED_PROXY"
  role    = "ACTIVE"

  # depends_on = [
  #   google_compute_forwarding_rule.nihonmachi_fr,
  #   google_compute_region_target_https_proxy.nihonmachi_https_proxy,
  #   google_compute_region_url_map.nihonmachi_url_map,
  #   google_compute_region_backend_service.nihonmachi_backend
  # ]
}