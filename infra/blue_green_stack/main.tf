module "compute_instance_group" {
  source                         = "./compute_instance_group"
  project_id                     = var.project_id
  region                         = var.region
  stack_name                     = var.stack_name
  instance_template_image        = var.instance_template_image
  instance_template_machine_type = var.instance_template_machine_type
}

resource "google_compute_health_check" "health_check" {
  project = var.project_id
  name    = "${var.stack_name}-health-check"
  http_health_check {
    port         = 80
    request_path = var.health_check_path
  }
}

resource "google_compute_backend_service" "backend_service" {
  project       = var.project_id
  name          = "${var.stack_name}-backend-service"
  region        = var.region
  health_checks = [google_compute_health_check.health_check.self_link]

  backend {
    group = module.compute_instance_group.instance_group.self_link
  }

  session_affinity = "NONE"
  enable_cdn       = false
}

resource "google_compute_url_map" "url_map" {
  project = var.project_id
  name    = "${var.stack_name}-url-map"
  region  = var.region

  default_service = google_compute_backend_service.backend_service.self_link
}

resource "google_compute_target_http_proxy" "http_proxy" {
  project = var.project_id
  name    = "${var.stack_name}-http-proxy"
  region  = var.region
  url_map = google_compute_url_map.url_map.self_link
}

resource "google_compute_forwarding_rule" "forwarding_rule" {
  project    = var.project_id
  name       = "${var.stack_name}-forwarding-rule"
  region     = var.region
  target     = google_compute_target_http_proxy.http_proxy.self_link
  port_range = "80"
  ip_address = module.compute_instance_group.global_address.address
}

output "global_address" {
  value = module.compute_instance_group.global_address
}

output "health_check" {
  value = google_compute_health_check.health_check
}

output "instance_group" {
  value = module.compute_instance_group.instance_group
}
