# Nihonmachi Health Check
resource "google_compute_region_health_check" "nihonmachi_hc" {
  name   = "${var.name_prefix}-hc"
  region = var.gcp_region

  https_health_check {
    port         = 443
    request_path = "/health"
  }
}

# Nihonmachi Backend Service
resource "google_compute_region_backend_service" "nihonmachi_backend" {
  name                  = "${var.name_prefix}-backend"
  region                = var.gcp_region
  protocol              = "HTTPS"
  port_name             = "https" # MUST match MIG named_port.name
  load_balancing_scheme = "INTERNAL_MANAGED"
  health_checks         = [google_compute_region_health_check.nihonmachi_hc.id]

  backend {
    group           = google_compute_region_instance_group_manager.nihonmachi_mig.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
    max_utilization = 0.8
  }

  depends_on = [google_compute_region_health_check.nihonmachi_hc]
}

# Nihonmachi URL Map
resource "google_compute_region_url_map" "nihonmachi_url_map" {
  name   = "${var.name_prefix}-url-map"
  region = var.gcp_region

  default_service = google_compute_region_backend_service.nihonmachi_backend.id
}

# Nihonmachi Target HTTPS Proxy
resource "google_compute_region_target_https_proxy" "nihonmachi_https_proxy" {
  name    = "${var.name_prefix}-https-proxy"
  region  = var.gcp_region
  url_map = google_compute_region_url_map.nihonmachi_url_map.id

  ssl_certificates = [
    google_compute_region_ssl_certificate.nihonmachi_lb_ssl.id
  ]
}

# Nihonmachi Private Service Connect Endpoint (represents AWS NLB)
resource "tls_private_key" "nihonmachi_lb_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Nihonmachi SSL Certificate
resource "tls_self_signed_cert" "nihonmachi_lb_cert" {
  private_key_pem = tls_private_key.nihonmachi_lb_key.private_key_pem

  subject {
    common_name  = "nihonmachi.internal"
    organization = "Japan Medical Lab"
  }

  validity_period_hours = 720
  early_renewal_hours   = 72

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["nihonmachi.internal"]
}

# Nihonmachi Regional SSL Certificate
resource "google_compute_region_ssl_certificate" "nihonmachi_lb_ssl" {
  name   = "${var.name_prefix}-ilb-ssl"
  region = var.gcp_region

  private_key = tls_private_key.nihonmachi_lb_key.private_key_pem
  certificate = tls_self_signed_cert.nihonmachi_lb_cert.cert_pem
}

# Nihonmachi Forwarding Rule (represents AWS NLB)
resource "google_compute_forwarding_rule" "nihonmachi_fr" {
  name                  = "${var.name_prefix}-fr"
  region                = var.gcp_region
  network               = google_compute_network.nihonmachi_vpc.id
  subnetwork            = google_compute_subnetwork.nihonmachi_private_subnet.id
  load_balancing_scheme = "INTERNAL_MANAGED"
  ip_protocol           = "TCP"
  port_range            = "443"
  target                = google_compute_region_target_https_proxy.nihonmachi_https_proxy.id

  depends_on = [
    google_compute_subnetwork.nihonmachi_proxy_subnet
  ]
}