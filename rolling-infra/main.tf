provider "google" {
  project     = var.gcp_project
  region      = var.gcp_region
  zone        = var.gcp_zone
  credentials = file("${var.credentials_file}")
}

locals {
  instance_name = var.instance_name
}

resource "google_compute_instance_template" "instance_template" {
  name_prefix  = "rolling-update-${local.instance_name}"
  machine_type = "n1-standard-1"
  //source_image     = google_compute_image.custom_image.self_link

  disk {
    auto_delete  = true
    boot         = true
    device_name  = "persistent-disk-0"
    mode         = "READ_WRITE"
    source_image = "ubuntu-minimal-2204-jammy-v20221101"
    //source_image = google_compute_image.custom_image.self_link
    type = "PERSISTENT"
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
  #       this is why we have a app_version in the name; this way
  #       new resource has a different name vs old one and both can
  #       exists at the same time
  lifecycle {
    create_before_destroy = true
  }

}

resource "google_compute_instance_group_manager" "instance_group_manager" {
  name               = "rolling-update-group-manager"
  base_instance_name = "rolling-update-instance"
  zone               = var.gcp_zone
  target_size        = 1

  version {
    instance_template = google_compute_instance_template.instance_template.self_link
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 2
    max_unavailable_fixed = 1
  }

  named_port {
    name = "http"
    port = 80
  }

  # NOTE: the name of this resource must be unique for eveey update;
  #       this is why we have a app_version in the name; this way
  #       new resource has a different name vs old one and both can
  #       exists at the same time
  lifecycle {
    create_before_destroy = true
  }

}

resource "google_compute_health_check" "http_health_check" {
  name = "http-health-check"
  http_health_check {
    port = 80
  }
  healthy_threshold   = 2
  unhealthy_threshold = 2
  timeout_sec         = 1
  check_interval_sec  = 5
}

resource "google_compute_backend_service" "backend_service" {
  name          = "rolling-update-backend"
  health_checks = [google_compute_health_check.http_health_check.self_link]

  backend {
    group = google_compute_instance_group_manager.instance_group_manager.instance_group
  }

  session_affinity = "NONE"
  enable_cdn       = false
}

resource "google_compute_url_map" "url_map" {
  name            = "rolling-update-url-map"
  default_service = google_compute_backend_service.backend_service.self_link
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "rolling-update-http-proxy"
  url_map = google_compute_url_map.url_map.self_link
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name        = "rolling-update-forwarding-rule"
  ip_protocol = "TCP"
  port_range  = "80"
  target      = google_compute_target_http_proxy.http_proxy.self_link
  ip_address  = google_compute_global_address.global_address.address
}

resource "google_compute_global_address" "global_address" {
  name = "rolling-update-global-address"
}
