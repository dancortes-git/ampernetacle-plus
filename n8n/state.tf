/*
 Terraform remote state configuration for the n8n database infrastructure
*/
data "terraform_remote_state" "n8n_db" {
  backend = "oci"

  config = {
    bucket    = var.bucket
    namespace = var.oci_namespace
    key       = var.n8n_db_key
  }
}

/*
 Terraform remote state configuration for the email delivery infrastructure
*/
data "terraform_remote_state" "email" {
  backend = "oci"

  config = {
    bucket    = var.bucket
    namespace = var.oci_namespace
    key       = var.email_key
  }
}

terraform {
  backend "oci" {
    key = "n8n/terraform.tfstate"
  }
}
