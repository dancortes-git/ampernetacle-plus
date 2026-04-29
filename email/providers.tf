terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "8.10.0"
    }
  }
}

provider "oci" {
  auth                = "SecurityToken"
  config_file_profile = "DEFAULT"
  region              = var.region
}
