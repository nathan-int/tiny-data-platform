resource "google_eventarc_trigger" "gcs-object-finalized" {
  name     = "gcs-object-finalized"
  location = var.region
  matching_criteria {
    attribute = "type"
    value = [
      "google.cloud.storage.object.v1.finalized",
      "google.cloud.storage.object.v1.metadataUpdated",
    ]
  }
  destination {
    cloud_run_service {
      service = google_cloud_run_service.default.name
      region  = var.region
    }
  }
  transport {
    pubsub {
      topic = google_pubsub_topic.platform_events_topic.id
    }
  }
  retry_policy {
    max_attempts = 1
  }
}