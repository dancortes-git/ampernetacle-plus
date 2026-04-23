terraform {
  backend "oci" {
    bucket    = "terraform-state"
    namespace = "grmwcomxkkbl"
    key       = "k8s/terraform.tfstate"
  }
}