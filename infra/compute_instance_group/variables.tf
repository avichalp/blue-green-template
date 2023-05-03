variable "project_id" {
  description = "GCP Project ID"
}

variable "region" {
  description = "GCP Region"
}

variable "stack_name" {
  description = "Stack name: blue, green or switch"
}

variable "instance_template_image" {
  description = "Instance image for the instance template"
}

variable "instance_template_machine_type" {
  description = "Instance machine type for the instance template"
}
