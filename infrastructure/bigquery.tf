resource "google_bigquery_dataset" "bronze" {
  dataset_id            = "bronze"
  friendly_name         = "Bronze Layer"
  description           = "Raw data ingested from various sources, used by Dataform"
  location              = "australia-southeast1"
  project               = var.project_id

  max_time_travel_hours = 168
  storage_billing_model = "PHYSICAL"
}

resource "google_bigquery_dataset" "silver" {
  dataset_id            = "silver"
  friendly_name         = "Silver Layer"
  description           = "Cleaned and conformed data, used by Dataform"
  location              = "australia-southeast1"
  project               = var.project_id

  max_time_travel_hours = 168
  storage_billing_model = "PHYSICAL"
}

resource "google_bigquery_dataset" "gold" {
  dataset_id            = "gold"
  friendly_name         = "Gold Layer"
  description           = "Curated data for business reporting, used by Dataform"
  location              = "australia-southeast1"
  project               = var.project_id

  max_time_travel_hours = 168
  storage_billing_model = "PHYSICAL"
}
