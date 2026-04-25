/*
 Terraform remote state configuration for the core and PostgreSQL infrastructure
*/
data "terraform_remote_state" "core" {
  backend = "oci"

  config = {
    bucket    = var.bucket
    namespace = var.oci_namespace
    key       = var.core_key
  }
}

data "terraform_remote_state" "postgresql" {
  backend = "oci"

  config = {
    bucket    = var.bucket
    namespace = var.oci_namespace
    key       = var.postgresql_key
  }
}

terraform {
  backend "oci" {
    key = "n8n_db/terraform.tfstate"
  }
}
