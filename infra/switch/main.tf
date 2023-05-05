resource "google_compute_health_check" "health_check" {
  project = var.gcp_project
  name    = "switch-health-check"
  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_global_address" "switch_global_address" {
  project = var.gcp_project
  name    = "switch-global-address"
}

resource "google_compute_backend_service" "switch_backend_service" {
  count                 = var.add_backend ? 0 : 1
  project               = var.gcp_project
  name                  = "switch-backend-service"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  timeout_sec           = 30
  health_checks = [
    google_compute_health_check.health_check.id
  ]

  backend {
    group           = var.instance_group_blue
    capacity_scaler = var.active_stack == "blue" ? 1.0 : 0.0
  }

  session_affinity = "NONE"
  enable_cdn       = false
}

resource "google_compute_url_map" "switch_url_map" {
  count   = var.add_backend ? 0 : 1
  project = var.gcp_project
  name    = "switch-url-map"

  default_service = google_compute_backend_service.switch_backend_service[count.index].self_link
}

resource "google_compute_target_http_proxy" "switch_http_proxy" {
  count   = var.add_backend ? 0 : 1
  project = var.gcp_project
  name    = "switch-http-proxy"
  url_map = google_compute_url_map.switch_url_map[count.index].self_link
}

resource "google_compute_global_forwarding_rule" "switch_forwarding_rule" {
  count                 = var.add_backend ? 0 : 1
  project               = var.gcp_project
  name                  = "switch-forwarding-rule"
  target                = google_compute_target_http_proxy.switch_http_proxy[count.index].self_link
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.switch_global_address.id
}

resource "google_compute_backend_service" "switch_backend_service_green" {
  count                 = var.add_backend ? 1 : 0
  project               = var.gcp_project
  name                  = "switch-backend-service-green"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  timeout_sec           = 30
  health_checks = [
    google_compute_health_check.health_check.id
  ]

  backend {
    group           = var.instance_group_blue
    capacity_scaler = var.active_stack == "blue" ? 1.0 : 0.0
  }

  backend {
    group           = var.instance_group_green
    capacity_scaler = var.active_stack == "green" ? 1.0 : 0.0
  }

  session_affinity = "NONE"
  enable_cdn       = false
}

resource "google_compute_url_map" "switch_url_map_green" {
  count   = var.add_backend ? 1 : 0
  project = var.gcp_project
  name    = "switch-url-map-green"

  default_service = google_compute_backend_service.switch_backend_service_green[count.index].self_link
}

resource "google_compute_target_http_proxy" "switch_http_proxy_green" {
  count   = var.add_backend ? 1 : 0
  project = var.gcp_project
  name    = "switch-http-proxy-green"
  url_map = google_compute_url_map.switch_url_map_green[count.index].self_link
}

resource "google_compute_global_forwarding_rule" "switch_forwarding_rule_green" {
  count                 = var.add_backend ? 1 : 0
  project               = var.gcp_project
  name                  = "switch-forwarding-rule-green"
  target                = google_compute_target_http_proxy.switch_http_proxy_green[count.index].self_link
  port_range            = "80"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.switch_global_address.id
}

