data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../cloud_functions/file_load"
  output_path = "${path.module}/../cloud_functions/file_load.zip"
}

resource "google_storage_bucket" "function_source_bucket" {
  name                        = "${var.project_id}-function-source"
  location                    = var.region
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_object" "function_zip_object" {
  name   = "function-source-${data.archive_file.function_zip.output_md5}.zip"
  bucket = google_storage_bucket.function_source_bucket.name
  source = data.archive_file.function_zip.output_path
}

resource "google_service_account" "function_sa" {
  account_id   = "file-load-function-sa"
  display_name = "Service Account for File Load Function"
}

resource "google_project_iam_member" "function_dataform_editor" {
  project = var.project_id
  role    = "roles/dataform.editor"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_project_iam_member" "function_storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_project_iam_member" "function_eventarc_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_cloudfunctions2_function" "file_load_function" {
  name        = "file-load-function"
  location    = var.region
  description = "Trigger Dataform on GCS object finalize"

  build_config {
    runtime     = "python310"
    entry_point = "process_gcs_event"
    source {
      storage_source {
        bucket = google_storage_bucket.function_source_bucket.name
        object = google_storage_bucket_object.function_zip_object.name
      }
    }
  }

  service_config {
    max_instance_count = 10
    timeout_seconds    = 3600
    available_memory   = "512M"
    environment_variables = {
      DATAFORM_PROJECT_ID = var.project_id
      DATAFORM_REGION     = var.region
      DATAFORM_REPOSITORY = google_dataform_repository.dataform_repo.name
      DATAFORM_WORKSPACE  = "landing-workspace"
    }
    service_account_email = google_service_account.function_sa.email
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.storage.object.v1.finalized"
    service_account_email = google_service_account.function_sa.email
    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.data_bucket.name
    }
  }
}
