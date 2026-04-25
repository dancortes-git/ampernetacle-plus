locals {
  db_database_name        = data.terraform_remote_state.n8n_db.outputs.db_database_name
  db_host                 = data.terraform_remote_state.n8n_db.outputs.db_host
  db_password_secret_name = data.terraform_remote_state.n8n_db.outputs.db_password_secret_name
  db_port                 = data.terraform_remote_state.n8n_db.outputs.db_port
  db_user                 = data.terraform_remote_state.n8n_db.outputs.db_user
  n8n_namespace           = data.terraform_remote_state.n8n_db.outputs.n8n_namespace
}

resource "helm_release" "n8n" {
  name             = var.release_name
  repository       = "https://community-charts.github.io/helm-charts"
  chart            = "n8n"
  version          = var.chart_version
  namespace        = local.n8n_namespace
  create_namespace = false

  values = [
    templatefile("${path.module}/values.yaml", {
      cert_manager_cluster_issuer = var.cert_manager_cluster_issuer
      db_database                 = local.db_database_name
      db_host                     = local.db_host
      db_password_secret_name     = local.db_password_secret_name
      db_port                     = local.db_port
      db_user                     = local.db_user
      ingress_class_name          = var.ingress_class_name
      n8n_host                    = var.n8n_host
      n8n_protocol                = var.n8n_protocol
      persistence_size            = var.persistence_size
      storage_class_name          = var.storage_class_name
      webhook_url                 = var.webhook_url
    })
  ]

  depends_on = [
    data.terraform_remote_state.n8n_db
  ]
}
