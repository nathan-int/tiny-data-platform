# A generic Pub/Sub topic to receive CloudEvents from any microservice or source
resource "google_pubsub_topic" "platform_events_topic" {
  name = "platform-events"
}

# Get the default Google Cloud Storage service account email
data "google_storage_project_service_account" "gcs_account" {
}

# Grant the GCS service account permission to publish to the generic topic
resource "google_pubsub_topic_iam_binding" "gcs_publisher_binding" {
  topic   = google_pubsub_topic.platform_events_topic.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}
