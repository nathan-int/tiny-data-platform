resource "google_dataform_repository" "dataform_repo" {
  provider = google-beta
  name     = "tiny-data-platform"
  region   = var.region
  project  = var.project_id
}
