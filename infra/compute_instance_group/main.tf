resource "google_compute_instance_template" "instance_template" {
  project      = var.project_id
  name         = "${var.stack_name}-instance-template"
  machine_type = var.instance_template_machine_type

  disk {
    boot         = true
    source_image = var.instance_template_image
  }

  network_interface {
    network = "default"
    access_config {
      # Ephemeral IP
    }
  }
}

resource "google_compute_instance_group_manager" "instance_group_manager" {
  project            = var.project_id
  name               = "${var.stack_name}-instance-group-manager"
  base_instance_name = "${var.stack_name}-instance"
  zone               = "${var.region}-a"

  version {
    instance_template = google_compute_instance_template.instance_template.self_link
  }

  target_size = 1
}

resource "google_compute_global_address" "global_address" {
  project = var.project_id
  name    = "${var.stack_name}-global-address"
}

output "instance_template" {
  value = google_compute_instance_template.instance_template
}

output "instance_group" {
  value = google_compute_instance_group_manager.instance_group_manager
}

output "global_address" {
  value = google_compute_global_address.global_address
}
