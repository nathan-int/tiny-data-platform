resource "google_storage_bucket" "data_bucket" {
  name          = "${var.project_id}-raw-data"
  location      = var.region
  force_destroy = true
  
  # Enable Autoclass for automatic lifecycle management of storage classes
  autoclass {
    enabled = true
  }

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 30 # Time To Live (TTL) of 30 days
    }
    action {
      type = "Delete"
    }
  }
}

# In GCP, folders in Cloud Storage are just prefixes on object names.
resource "google_storage_bucket_object" "landing_folder" {
  name    = "landing/"
  content = " "
  bucket  = google_storage_bucket.data_bucket.name
}

resource "google_storage_bucket_object" "archive_folder" {
  name    = "archive/"
  content = " "
  bucket  = google_storage_bucket.data_bucket.name
}
