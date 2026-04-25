resource "kubernetes_namespace_v1" "postgresql" {
  metadata {
    name = var.postgresql_namespace
  }
}

resource "random_password" "postgresql" {
  length           = 24
  special          = true
  override_special = "_-@#%"
}

resource "kubernetes_secret_v1" "postgresql" {
  metadata {
    name      = var.postgresql_secret_name
    namespace = kubernetes_namespace_v1.postgresql.metadata[0].name
  }

  data = {
    postgresql-password = random_password.postgresql.result
  }

  type = "Opaque"
}

resource "helm_release" "postgresql" {
  name             = "postgresql"
  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "postgresql"
  version          = "18.3.0"
  namespace        = kubernetes_namespace_v1.postgresql.metadata[0].name
  create_namespace = false

  values = [
    file("${path.module}/values.yaml")
  ]

  depends_on = [
    kubernetes_secret_v1.postgresql
  ]
}
