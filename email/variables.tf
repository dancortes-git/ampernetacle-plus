variable "bucket" {
  description = "OCI Object Storage bucket that stores Terraform state."
  type        = string
}

variable "oci_namespace" {
  description = "OCI Object Storage namespace that stores Terraform state."
  type        = string
}

variable "root_key" {
  description = "OCI Object Storage key for the root infrastructure Terraform state."
  type        = string
}

variable "smtp_user_id" {
  description = "OCID of the OCI IAM user that will own the SMTP credentials."
  type        = string
}

variable "smtp_sender_email" {
  description = "Email address to register as an approved sender in OCI Email Delivery."
  type        = string
}

variable "region" {
  description = "OCI region where the cluster and email delivery service are located."
  type        = string
  default     = "sa-saopaulo-1"
}
