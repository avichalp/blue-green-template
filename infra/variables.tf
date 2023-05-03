variable "project_id" {
  description = "GCP Project ID"
}

variable "region" {
  description = "GCP Region"
}

variable "blue_name" {
  default = "blue"
}

variable "green_name" {
  default = "green"
}

variable "switch_name" {
  default = "switch"
}

variable "instance_template_image" {
  description = "Instance image for both Blue and Green instance templates"
}

variable "instance_template_machine_type" {
  description = "Instance machine type for both Blue and Green instance templates"
}

variable "health_check_path" {
  default = "/health"
}
