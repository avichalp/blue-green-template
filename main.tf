terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.49.0"
    }
  }
}

variable "vm_name" {
  type = string
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

variable "user" {
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


resource "google_compute_instance" "validator" {
  name         = var.vm_name
  machine_type = var.machine_type
  tags         = ["https-server", "grafana", "ssh-vm"]

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2204-jammy-v20221101"
      type  = "pd-ssd"
      size  = "50"
    }
  }

  service_account {
    scopes = ["service-control", "service-management", "storage-rw", "monitoring", "logging-write", "trace"]
  }


  network_interface {
    network = "default"
    access_config {}
  }

  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/tmp/bootstrap.sh"

    connection {
      type        = "ssh"
      user        = var.user
      timeout     = "500s"
      private_key = file("~/.ssh/google_compute_engine")
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }

}

/* resource "google_compute_target_pool" "target_pool" {
  name = "my-target-pool"
}

resource "google_compute_instance_group_manager" "igm" {
  name               = "my-instance-group"
  target_pools       = [google_compute_target_pool.target_pool.self_link]
  base_instance_name = "my-instance"
  zone               = "us-central1-a"
  instance_template  = google_compute_instance_template.template.self_link

  named_port {
    name = "http"
    port = 80
  }

  target_size = 2

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 1
    max_unavailable_fixed = 0
  }
}

resource "google_compute_autoscaler" "autoscaler" {
  name = "my-autoscaler"
  zone = "us-central1-a"

  target = google_compute_instance_group_manager.igm.self_link

  autoscaling_policy {
    scale_down_control {
      time_window_sec          = 300
      stabilization_window_sec = 300
    }

    cpu_utilization {
      target = 0.5
    }

    min_replicas = 2
    max_replicas = 5
  }
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name       = "my-forwarding-rule"
  target     = google_compute_target_http_proxy.http_proxy.self_link
  port_range = "80"
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
    group = google_compute_instance_group_manager.igm.self_link
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
 */
