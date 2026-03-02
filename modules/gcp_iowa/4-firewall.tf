# Firewall rules for Nihonmachi app instances
resource "google_compute_firewall" "allow_https_from_vpn" {
  name    = "nihonmachi-allow-https-from-vpn"
  network = google_compute_network.nihonmachi_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = var.allowed_vpn_cidrs
  target_tags   = ["nihonmachi-app"]
}

# Allow LB proxy subnet to reach backends on 443
resource "google_compute_firewall" "allow_https_from_proxy" {
  name    = "nihonmachi-allow-https-from-proxy"
  network = google_compute_network.nihonmachi_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [var.nihonmachi_proxy_subnet_cidr]
  target_tags   = ["nihonmachi-app"]
}

# Allow Google health checks to reach backends
resource "google_compute_firewall" "allow_hc" {
  name        = "nihonmachi-allow-hc"
  network     = google_compute_network.nihonmachi_vpc.name
  description = "Allow Google health checks to reach app instances on 443"

  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]

  target_tags = ["nihonmachi-app"]
}

# Allow SSH from GCP Cloud Shell for troubleshooting (optional)
resource "google_compute_firewall" "nihonmachi_allow_ssh" {
  name      = "nihonmachi-allow-ssh"
  network   = google_compute_network.nihonmachi_vpc.id
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["nihonmachi-app"]
}

# Egress allow ONLY to AWS Tokyo VPC CIDR on 443 and DB port (3306 default)
resource "google_compute_firewall" "allow_egress_to_aws" {
  name        = "nihonmachi-allow-egress-to-aws"
  network     = google_compute_network.nihonmachi_vpc.name
  direction   = "EGRESS"
  priority    = 800
  target_tags = ["nihonmachi-app"]

  allow {
    protocol = "tcp"
    ports    = ["443", tostring(var.tokyo_rds_port)]
  }

  destination_ranges = [var.aws_vpc_cidr]
}

# Deny all other egress (prevents accidental data persistence services, exfil, etc.)
resource "google_compute_firewall" "deny_all_other_egress" {
  name        = "nihonmachi-deny-all-egress"
  network     = google_compute_network.nihonmachi_vpc.name
  direction   = "EGRESS"
  priority    = 1000
  target_tags = ["nihonmachi-app"]

  deny {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

# Allow app instances to reach out to the internet for bootstrap and updates on 443 (but not 80)
resource "google_compute_firewall" "nihonmachi_allow_egress_bootstrap" {
  name      = "nihonmachi-allow-egress-bootstrap"
  network   = google_compute_network.nihonmachi_vpc.id
  direction = "EGRESS"
  priority  = 900

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["nihonmachi-app"]
}

# Allow app instances to reach out to DNS on 53 (TCP and UDP)
resource "google_compute_firewall" "nihonmachi_allow_egress_dns" {
  name      = "nihonmachi-allow-egress-dns"
  network   = google_compute_network.nihonmachi_vpc.id
  direction = "EGRESS"
  priority  = 800

  allow {
    protocol = "udp"
    ports    = ["53"]
  }

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }

  destination_ranges = ["0.0.0.0/0"]
  target_tags        = ["nihonmachi-app"]
}