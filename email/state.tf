/*
 Terraform remote state configuration for the email delivery infrastructure
*/
data "terraform_remote_state" "root" {
  backend = "oci"

  config = {
    auth                = "SecurityToken"
    bucket              = var.bucket
    config_file_profile = "DEFAULT"
    key                 = var.root_key
    namespace           = var.oci_namespace
    region              = var.region
  }
}

terraform {
  backend "oci" {
    key = "email/terraform.tfstate"
  }
}
