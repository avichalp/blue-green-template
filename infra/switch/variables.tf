variable "gcp_project" {
  description = "GCP Project ID"
}

variable "gcp_region" {
  description = "GCP Region"
}

variable "gcp_zone" {
  description = "GCP Zone"
}

variable "active_stack" {
  description = "The active stack for the third load balancer to forward traffic to. Set to 'blue' or 'green'."
  default     = "blue"
}

variable "instance_group_blue" {
  type = any
}

variable "instance_group_green" {
  type = any
}

