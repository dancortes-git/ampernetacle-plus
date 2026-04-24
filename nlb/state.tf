/*
 Terraform remote state configuration for the core infrastructure
*/
data "terraform_remote_state" "core" {
  backend = "oci"

  config = {
    bucket    = var.bucket
    namespace = var.namespace
    key       = var.core_key
  }
}

terraform {
  backend "oci" {
    key       = "k8s-nlb/terraform.tfstate"
  }
}