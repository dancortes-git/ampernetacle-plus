terraform {
  backend "oci" {
    key = "k8s/terraform.tfstate"
  }
}