# Nihonmachi VPC
resource "google_compute_network" "nihonmachi_vpc" {
  name                    = "nihonmachi-vpc"
  auto_create_subnetworks = false
}

# Nihonmachi private subnet
resource "google_compute_subnetwork" "nihonmachi_private_subnet" {
  name                     = "nihonmachi-subnet"
  region                   = var.gcp_region
  network                  = google_compute_network.nihonmachi_vpc.id
  ip_cidr_range            = var.nihonmachi_subnet_cidr
  private_ip_google_access = true
}

# Nihonmachi proxy subnet
resource "google_compute_subnetwork" "nihonmachi_proxy_subnet" {
  name          = "nihonmachi-proxy-subnet"
  ip_cidr_range = var.nihonmachi_proxy_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.nihonmachi_vpc.id

  purpose = "REGIONAL_MANAGED_PROXY"
  role    = "ACTIVE"
}