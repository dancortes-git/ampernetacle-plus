locals {
  db_host                 = var.db_host != "" ? var.db_host : "${var.postgresql_service_name}.${data.terraform_remote_state.postgresql.outputs.postgresql_namespace}.svc.cluster.local"
  postgresql_namespace    = data.terraform_remote_state.postgresql.outputs.postgresql_namespace
  postgresql_secret_name  = data.terraform_remote_state.postgresql.outputs.postgresql_secret_name
  db_port                 = 5432
  db_password_secret_key  = "password"
  db_password_secret_type = "Opaque"
}

resource "kubernetes_namespace_v1" "application" {
  metadata {
    name = var.application_namespace
  }
}

resource "random_password" "database" {
  length           = 32
  special          = true
  override_special = "_-@#%"
}

resource "kubernetes_secret_v1" "database_job" {
  metadata {
    name      = var.db_password_secret_name
    namespace = local.postgresql_namespace
  }

  data = {
    (local.db_password_secret_key) = random_password.database.result
  }

  type = local.db_password_secret_type
}

resource "kubernetes_secret_v1" "database_application" {
  metadata {
    name      = var.db_password_secret_name
    namespace = kubernetes_namespace_v1.application.metadata[0].name
  }

  data = {
    (local.db_password_secret_key) = random_password.database.result
  }

  type = local.db_password_secret_type
}

resource "helm_release" "database_init" {
  name             = "n8n-db-init"
  chart            = "${path.module}/chart"
  namespace        = local.postgresql_namespace
  create_namespace = false

  values = [
    yamlencode({
      db = {
        host      = local.db_host
        port      = local.db_port
        sslmode   = "disable"
        adminUser = var.db_admin_user
        adminPasswordSecret = {
          name = local.postgresql_secret_name
          key  = var.postgresql_admin_password_key
        }
        name = var.db_name
        user = var.db_user
        passwordSecret = {
          create = false
          name   = var.db_password_secret_name
          key    = local.db_password_secret_key
        }
      }
    })
  ]

  depends_on = [
    data.terraform_remote_state.postgresql,
    kubernetes_secret_v1.database_application,
    kubernetes_secret_v1.database_job
  ]
}
