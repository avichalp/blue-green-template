locals {
  stack_names = [var.blue_name, var.green_name, var.switch_name]
}

module "blue_green_stacks" {
  source = "./blue_green_stack"
  for_each = toset(local.stack_names)

  project_id = var.project_id
  region = var.region
  stack_name = each.value

  instance_template_image = var.instance_template_image
  instance_template_machine_type = var.instance_template_machine_type
  health_check_path = var.health_check_path
}

resource "google_compute_backend_service" "switch_backend_service" {
  project = var.project_id
  name = "${var.switch_name}-backend-service"
  region = var.region
  health_checks = [
    module.blue_green_stacks[var.blue_name].health_check.self_link,
    module.blue_green_stacks[var.green_name].health_check.self_link,
  ]

  backend {
    group = module.blue_green_stacks[var.blue_name].instance_group.self_link
    capacity_scaler = 1
  }

  backend {
    group = module.blue_green_stacks[var.green_name].instance_group.self_link
    capacity_scaler = 0
  }

  session_affinity = "NONE"
  enable_cdn = false
}

resource "google_compute_url_map" "switch_url_map" {
  project = var.project_id
  name = "${var.switch_name}-url-map"
  region = var.region

  default_service = google_compute_backend_service.switch_backend_service.self_link
}

resource "google_compute_target_http_proxy" "switch_http_proxy" {
  project = var.project_id
  name = "${var.switch_name}-http-proxy"
  region = var.region
  url_map = google_compute_url_map.switch_url_map.self_link
}

resource "google_compute_forwarding_rule" "switch_forwarding_rule" {
  project = var.project_id
  name = "${var.switch_name}-forwarding-rule"
  region = var.region
  target = google_compute_target_http_proxy.switch_http_proxy.self_link
  port_range = "80"
  ip_address = module.blue_green_stacks[var.switch_name].global_address.address
}
