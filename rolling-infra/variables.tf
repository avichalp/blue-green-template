variable "gcp_project" {
  description = "The project ID to deploy resources."
}

variable "gcp_region" {
  description = "The GCP region to deploy resources."
  default     = "us-west1"
}

variable "gcp_zone" {
  description = "The GCP zone to deploy resources."
  default     = "us-west1-b"
}

variable "credentials_file" {
  type = string
}


variable "machine_type" {
  description = "The machine type for the instances."
  default     = "n1-standard-1"
}

variable "source_image" {
  description = "The source image for the instances."
  default     = "projects/debian-cloud/global/images/family/debian-10"
}

variable "network" {
  description = "The network for the instances."
  default     = "default"
}

variable "instance_name" {
  description = "The name for the instances."
  default     = "rolling-instance"
}
