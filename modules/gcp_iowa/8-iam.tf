resource "google_service_account" "nihonmachi_sa" {
  account_id   = "nihonmachi-sa"
  display_name = "Nihonmachi MIG service account"
}

# Allows the VM startup script to read the DB password from Secret Manager
# (Project-wide for simplicity; you can tighten later to a single secret.)
resource "google_project_iam_member" "nihonmachi_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.nihonmachi_sa.email}"
}

resource "google_project_iam_member" "nihonmachi_logging_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.nihonmachi_sa.email}"
}
