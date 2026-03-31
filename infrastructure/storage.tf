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

resource "google_storage_notification" "notification" {
  bucket         = google_storage_bucket.data_bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.platform_events_topic.id
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_binding.gcs_publisher_binding]
}
