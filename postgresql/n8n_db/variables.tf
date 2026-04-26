variable "application_namespace" {
  description = "Kubernetes namespace where the application will read the database credentials."
  type        = string
  default     = "n8n"
}

variable "bucket" {
  description = "OCI Object Storage bucket that stores Terraform state."
  type        = string
}

variable "core_key" {
  description = "OCI Object Storage key for the core infrastructure Terraform state."
  type        = string
}

variable "db_admin_user" {
  description = "PostgreSQL administrator username used by the initialization Job."
  type        = string
  default     = "postgres"
}

variable "db_host" {
  description = "PostgreSQL service DNS name. When empty, it is built from postgresql_service_name and the PostgreSQL namespace remote state output."
  type        = string
  default     = "postgresql.postgresql"
}

variable "db_name" {
  description = "Application database name to initialize."
  type        = string
  default     = "n8n"
}

variable "db_password_secret_name" {
  description = "Kubernetes Secret name that stores the application database password."
  type        = string
  default     = "n8n-db-secret"
}

variable "db_user" {
  description = "Application database username to initialize."
  type        = string
  default     = "n8n"
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file used to connect to the Kubernetes cluster."
  type        = string
  default     = "../../kubeconfig"
}

variable "oci_namespace" {
  description = "OCI Object Storage namespace that stores Terraform state."
  type        = string
}

variable "postgresql_admin_password_key" {
  description = "Key in the PostgreSQL admin Secret that stores the admin password."
  type        = string
  default     = "postgresql-password"
}

variable "postgresql_key" {
  description = "OCI Object Storage key for the PostgreSQL Terraform state."
  type        = string
  default     = "postgresql/terraform.tfstate"
}

variable "postgresql_service_name" {
  description = "Kubernetes Service name used to reach PostgreSQL."
  type        = string
  default     = "postgres-postgresql"
}
