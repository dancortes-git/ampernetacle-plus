/*
 Terraform remote state configuration for the core infrastructure
*/
data "terraform_remote_state" "core" {
  backend = "oci"

  config = {
    bucket    = var.bucket
    namespace = var.oci_namespace
    key       = var.core_key
  }
}

terraform {
  backend "oci" {
    key = "postgresql/terraform.tfstate"
  }
}
