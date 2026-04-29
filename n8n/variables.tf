variable "bucket" {
  description = "OCI Object Storage bucket that stores Terraform state."
  type        = string
}

variable "chart_version" {
  description = "Version of the community-charts n8n Helm chart to install."
  type        = string
  default     = "1.16.37"
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig file used to connect to the Kubernetes cluster."
  type        = string
  default     = "../kubeconfig"
}

variable "n8n_db_key" {
  description = "OCI Object Storage key for the n8n database Terraform state."
  type        = string
}

variable "email_key" {
  description = "OCI Object Storage key for the email delivery Terraform state."
  type        = string
}

variable "persistence_size" {
  description = "Persistent volume size requested by the n8n Helm chart."
  type        = string
  default     = "5Gi"
}

variable "oci_namespace" {
  description = "OCI Object Storage namespace that stores Terraform state."
  type        = string
}

variable "release_name" {
  description = "Helm release name for n8n."
  type        = string
  default     = "n8n"
}

variable "storage_class_name" {
  description = "StorageClass used by the n8n chart for dynamic PersistentVolume provisioning."
  type        = string
  default     = "nfs-dynamic"
}

variable "ingress_class_name" {
  description = "IngressClass name used by the n8n Ingress."
  type        = string
  default     = "nginx"
}

variable "cert_manager_cluster_issuer" {
  description = "cert-manager ClusterIssuer used to issue the n8n TLS certificate."
  type        = string
  default     = "letsencrypt-prod"
}

variable "n8n_protocol" {
  description = "Public protocol used by n8n URLs."
  type        = string
  default     = "https"

  validation {
    condition     = contains(["http", "https"], var.n8n_protocol)
    error_message = "n8n_protocol must be either http or https."
  }
}

variable "n8n_host" {
  description = "Public DNS host used to access n8n."
  type        = string
}
