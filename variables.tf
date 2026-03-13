variable "project_id" {
  description = "The ID of the Google Cloud project"
  type        = string
  default     = "nathan-sandpit"
}

variable "region" {
  description = "The region to deploy resources in"
  type        = string
  default     = "australia-southeast1" # Update this to your preferred region (e.g., us-central1)
}

variable "zone" {
  description = "The zone to deploy resources in"
  type        = string
  default     = "australia-southeast1-a"
}
