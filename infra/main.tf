provider "google" {
  credentials = file("${var.credentials_file}")
  project     = var.gcp_project
  region      = var.gcp_region
  zone        = var.gcp_zone
}

module "switch" {
  source               = "./switch"
  gcp_project          = var.gcp_project
  gcp_region           = var.gcp_region
  gcp_zone             = var.gcp_zone
  active_stack         = var.active_stack
  instance_group_blue  = module.blue.instance_group_manager[0].instance_group
  instance_group_green = var.deployment ? module.green.instance_group_manager[0].instance_group : ""
  add_backend          = var.deployment
}

module "blue" {
  source       = "./blue_green_stack"
  gcp_project  = var.gcp_project
  gcp_region   = var.gcp_region
  gcp_zone     = var.gcp_zone
  stack_name   = "blue"
  app_version  = var.blue_version
  create_stack = true
}

module "green" {
  source       = "./blue_green_stack"
  gcp_project  = var.gcp_project
  gcp_region   = var.gcp_region
  gcp_zone     = var.gcp_zone
  stack_name   = "green"
  app_version  = var.green_version
  create_stack = var.deployment
}


