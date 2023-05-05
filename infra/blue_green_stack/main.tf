resource "google_compute_instance_template" "instance_template" {
  name         = "${var.stack_name}-instance-template-${var.app_version}"
  machine_type = "n1-standard-1"

  disk {
    auto_delete  = true
    boot         = true
    device_name  = "persistent-disk-0"
    mode         = "READ_WRITE"
    source_image = "ubuntu-minimal-2204-jammy-v20221101"
    type         = "PERSISTENT"
  }

  metadata_startup_script = file("./bootstrap.sh")

  network_interface {
    network = "default"
    access_config {
      # Ephemeral IP
    }
  }
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }
  tags = ["load-balanced-backend"]

  # NOTE: the name of this resource must be unique for eveey update;
  #       this is wy we have a app_version in the name; this way
  #       new resource has a different name vs old one and both can
  #       exists at the same time
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "instance_group_manager" {
  name               = "${var.stack_name}-instance-group-manager-${var.app_version}"
  base_instance_name = "${var.stack_name}-instance"
  zone               = var.gcp_zone

  named_port {
    name = "http"
    port = 80
  }

  version {
    instance_template = google_compute_instance_template.instance_template.self_link
  }

  target_size = 1

  # NOTE: the name of this resource must be unique for eveey update;
  #       this is wy we have a app_version in the name; this way
  #       new resource has a different name vs old one and both can
  #       exists at the same time
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_global_address" "global_address" {
  project = var.gcp_project
  name    = "${var.stack_name}-global-address"
}

resource "google_compute_health_check" "health_check" {
  project = var.gcp_project
  name    = "${var.stack_name}-health-check"
  http_health_check {
    port         = 80
    request_path = "/"
  }
}

resource "google_compute_backend_service" "backend_service" {
  project       = var.gcp_project
  name          = "${var.stack_name}-backend-service"
  health_checks = [google_compute_health_check.health_check.self_link]

  backend {
    group = google_compute_instance_group_manager.instance_group_manager.instance_group
  }

  session_affinity = "NONE"
  enable_cdn       = false
}

resource "google_compute_url_map" "url_map" {
  project = var.gcp_project
  name    = "${var.stack_name}-url-map"

  default_service = google_compute_backend_service.backend_service.self_link
}

resource "google_compute_target_http_proxy" "http_proxy" {
  project = var.gcp_project
  name    = "${var.stack_name}-http-proxy"
  url_map = google_compute_url_map.url_map.self_link
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  project    = var.gcp_project
  name       = "${var.stack_name}-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.self_link
  port_range = "80"
  ip_address = google_compute_global_address.global_address.id
}

output "instance_group_manager" {
  value = google_compute_instance_group_manager.instance_group_manager
}
