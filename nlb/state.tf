data "terraform_remote_state" "core" {
  backend = "oci"

  config = {
    bucket           = "terraform-state"
    namespace        = "grmwcomxkkbl"
    key              = "k8s/terraform.tfstate"
  }
}

terraform {
  backend "oci" {
    bucket    = "terraform-state"
    namespace = "grmwcomxkkbl"
    key       = "k8s-nlb/terraform.tfstate"
  }
}