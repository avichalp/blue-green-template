terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.49.0"
    }
  }
}

variable "machine_type" {
  type = string
}

variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_zone" {
  type = string
}

variable "credentials_file" {
  type = string
}


provider "google" {
  credentials = file("${var.credentials_file}")
  project     = var.gcp_project
  region      = var.gcp_region
  zone        = var.gcp_zone
}


resource "google_compute_instance_template" "my-instance" {
  name         = "my-instance-template"
  machine_type = var.machine_type
  tags         = ["https-server", "grafana", "ssh-vm"]

  disk {
    auto_delete  = true
    boot         = true
    device_name  = "persistent-disk-0"
    mode         = "READ_WRITE"
    source_image = "ubuntu-minimal-2204-jammy-v20221101"
    type         = "pd-ssd"
  }

  service_account {
    scopes = ["service-control", "service-management", "storage-rw", "monitoring", "logging-write", "trace"]
  }


  network_interface {
    network = "default"
    access_config {

    }
  }

  metadata_startup_script = file("${path.module}/bootstrap.sh")
}

resource "google_compute_instance_group_manager" "igm" {
  name               = "my-instance-group"
  base_instance_name = "my-instance"
  zone               = var.gcp_zone

  named_port {
    name = "http"
    port = 80
  }

  version {
    instance_template = google_compute_instance_template.my-instance.self_link
  }

  target_size = 2

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 1
    max_unavailable_fixed = 0
  }
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "my-http-proxy"
  url_map = google_compute_url_map.url_map.self_link
}

resource "google_compute_url_map" "url_map" {
  name            = "my-url-map"
  default_service = google_compute_backend_service.backend_service.self_link
}

resource "google_compute_backend_service" "backend_service" {
  name        = "my-backend-service"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group_manager.igm.instance_group
  }

  health_checks = [
    google_compute_http_health_check.health_check.self_link,
  ]
}

resource "google_compute_http_health_check" "health_check" {
  name                = "my-health-check"
  request_path        = "/"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name       = "my-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.self_link
  port_range = "80"
  ip_address = google_compute_global_address.global_address.address
}

resource "google_compute_global_address" "global_address" {
  name = "my-global-address"
}

// Uncolored
resource "google_compute_firewall" "allow_health_check" {
  name    = "allow-health-check"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  # Health check probes come from addresses in the ranges 130.211.0.0/22 and 35.191.0.0/16
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

