# The Pub/Sub topic where GCS notifications will be sent
resource "google_pubsub_topic" "gcs_events_topic" {
  name = "gcs-file-events"
}
