terraform {
  required_version = ">= 1.5"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "3.1.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "3.1.0"
    }

    oci = {
      source  = "oracle/oci"
      version = "8.10.0"
    }
  }
}

provider "helm" {
  repository_config_path = "${path.module}/helm-repositories.yaml"
  repository_cache       = "${path.module}/.terraform/helm/repository"

  kubernetes = {
    config_path = var.kubeconfig_path
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}
