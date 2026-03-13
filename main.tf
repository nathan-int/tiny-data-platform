# Main configuration for tiny-data-platform
# By keeping resource definitions inside the 'infrastructure' module, 
# we separate concerns and keep the root clean for other tools like Dataform.

module "infrastructure" {
  source     = "./infrastructure"
  project_id = var.project_id
  region     = var.region
}
