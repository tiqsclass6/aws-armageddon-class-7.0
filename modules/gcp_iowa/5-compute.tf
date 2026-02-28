data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

locals {
  startup_script = replace(
    templatefile("${path.module}/startup.sh.tftpl", {
      tokyo_rds_host = var.tokyo_rds_host
      tokyo_rds_port = var.tokyo_rds_port
      tokyo_rds_user = var.tokyo_rds_user
      secret_name    = var.db_password_secret_name
    }),
    "\r\n", "\n"
  )
}

resource "google_compute_instance_template" "nihonmachi_tpl" {
  name_prefix  = "nihonmachi-tpl"
  machine_type = var.machine_type
  tags         = ["nihonmachi-app"]

  service_account {
    email  = google_service_account.nihonmachi_sa.email
    scopes = ["cloud-platform"]
  }

  disk {
    source_image = data.google_compute_image.debian.self_link
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.nihonmachi_private_subnet.id
  }

  metadata_startup_script = local.startup_script

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "nihonmachi_mig" {
  name   = "nihonmachi-mig"
  region = var.gcp_region

  version {
    instance_template = google_compute_instance_template.nihonmachi_tpl.id
  }

  base_instance_name = "nihonmachi-app"
  target_size        = var.mig_size

  named_port {
    name = "https"
    port = 443
  }

  auto_healing_policies {
    health_check      = google_compute_region_health_check.nihonmachi_hc.id
    initial_delay_sec = 60
  }

  update_policy {
    type           = "PROACTIVE"
    minimal_action = "REPLACE"

    max_surge_fixed       = 3
    max_unavailable_fixed = 0
  }
}

resource "google_compute_region_autoscaler" "nihonmachi_autoscaler" {
  count  = var.enable_autoscaling ? 1 : 0
  name   = "${var.name_prefix}-autoscaler"
  region = var.gcp_region
  target = google_compute_region_instance_group_manager.nihonmachi_mig.id

  autoscaling_policy {
    min_replicas    = var.autoscaler_min_replicas
    max_replicas    = var.autoscaler_max_replicas
    cooldown_period = var.autoscaler_cooldown_sec

    cpu_utilization {
      target = var.autoscaler_cpu_target
    }
  }
}