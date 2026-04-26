variable "bucket" {
  description = "OCI Object Storage bucket that stores Terraform state."
  type        = string
}

variable "namespace" {
  description = "OCI Object Storage namespace that stores Terraform state."
  type        = string
}

variable "core_key" {
  description = "OCI Object Storage key for the core infrastructure Terraform state."
  type        = string
}
