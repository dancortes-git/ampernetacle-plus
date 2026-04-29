/*
 Terraform remote state configuration for the email delivery infrastructure
*/
data "terraform_remote_state" "root" {
  backend = "oci"

  config = {
    bucket    = var.bucket
    namespace = var.oci_namespace
    key       = var.root_key
  }
}

terraform {
  backend "oci" {
    key = "email/terraform.tfstate"
  }
}
