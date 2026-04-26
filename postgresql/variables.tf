variable "bucket" {
  description = "OCI Object Storage bucket that stores Terraform state."
  type        = string
}

variable "core_key" {
  description = "OCI Object Storage key for the core infrastructure Terraform state."
  type        = string
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file used to connect to the Kubernetes cluster."
  type        = string
  default     = "../kubeconfig"
}

variable "postgresql_namespace" {
  description = "Kubernetes namespace where PostgreSQL will be installed."
  type        = string
  default     = "postgresql"
}

variable "oci_namespace" {
  description = "OCI Object Storage namespace that stores Terraform state."
  type        = string
}

variable "postgresql_secret_name" {
  description = "Name of the Kubernetes Secret that stores the PostgreSQL admin password."
  type        = string
  default     = "postgresql-auth"
}
