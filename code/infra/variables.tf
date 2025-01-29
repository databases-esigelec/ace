# variables.tf
variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "The region to deploy resources to"
  type        = string
  default     = "europe-west1"
}

variable "zone" {
  description = "The zone to deploy GKE cluster"
  type        = string
  default     = "europe-west1-b"
}

variable "credentials" {
  description = "Path to the GCP credentials file"
  type        = string

}