# Service Account for the MIG VMs
resource "google_service_account" "nihonmachi_sa" {
  account_id   = "nihonmachi-sa"
  display_name = "Nihonmachi MIG service account"
}

# Grant the service account permissions to access secrets and write logs
resource "google_project_iam_member" "nihonmachi_secret_accessor" {
  project = var.gcp_project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.nihonmachi_sa.email}"
}

# Grant the service account permissions to write logs for the MIG VMs
resource "google_project_iam_member" "nihonmachi_logging_writer" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.nihonmachi_sa.email}"
}