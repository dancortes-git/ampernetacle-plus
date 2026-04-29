locals {
  db_database_name        = data.terraform_remote_state.n8n_db.outputs.db_database_name
  db_host                 = data.terraform_remote_state.n8n_db.outputs.db_host
  db_password_secret_name = data.terraform_remote_state.n8n_db.outputs.db_password_secret_name
  db_port                 = data.terraform_remote_state.n8n_db.outputs.db_port
  db_user                 = data.terraform_remote_state.n8n_db.outputs.db_user
  n8n_namespace           = data.terraform_remote_state.n8n_db.outputs.n8n_namespace
  smtp_host               = data.terraform_remote_state.email.outputs.smtp_host
  smtp_user               = data.terraform_remote_state.email.outputs.smtp_user
  smtp_sender             = data.terraform_remote_state.email.outputs.smtp_sender_email
  smtp_secret_name        = "n8n-smtp-credentials"
  runner_labels = {
    "app.kubernetes.io/name"       = "n8n-python-runner"
    "app.kubernetes.io/instance"   = var.release_name
    "app.kubernetes.io/component"  = "task-runner"
    "app.kubernetes.io/part-of"    = "n8n"
    "app.kubernetes.io/managed-by" = "terraform"
  }
  runner_service_name = "n8n-task-broker"
  webhook_url         = "${var.n8n_protocol}://${var.n8n_host}/"
}

resource "random_password" "runner_auth_token" {
  length  = 32
  special = false
}

resource "kubernetes_secret_v1" "runner_auth" {
  metadata {
    name      = "n8n-runner-auth"
    namespace = local.n8n_namespace

    labels = local.runner_labels
  }

  data = {
    N8N_RUNNERS_AUTH_TOKEN = random_password.runner_auth_token.result
  }

  type                           = "Opaque"
  wait_for_service_account_token = false
}

resource "kubernetes_secret_v1" "smtp_credentials" {
  metadata {
    name      = local.smtp_secret_name
    namespace = local.n8n_namespace
  }

  data = {
    N8N_SMTP_PASS = data.terraform_remote_state.email.outputs.smtp_password
  }

  type                           = "Opaque"
  wait_for_service_account_token = false
}

resource "kubernetes_service_account_v1" "runner" {
  metadata {
    name      = "n8n-python-runner"
    namespace = local.n8n_namespace

    labels = local.runner_labels
  }

  automount_service_account_token = false
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
      smtp_host                   = local.smtp_host
      smtp_secret_name            = local.smtp_secret_name
      smtp_sender                 = local.smtp_sender
      smtp_user                   = local.smtp_user
      storage_class_name          = var.storage_class_name
      webhook_url                 = local.webhook_url
    })
  ]

  depends_on = [
    data.terraform_remote_state.n8n_db,
    kubernetes_secret_v1.runner_auth,
    kubernetes_secret_v1.smtp_credentials
  ]
}

resource "kubernetes_service_v1" "task_broker" {
  metadata {
    name      = local.runner_service_name
    namespace = local.n8n_namespace

    labels = local.runner_labels
  }

  spec {
    selector = {
      "app.kubernetes.io/name"     = "n8n"
      "app.kubernetes.io/instance" = var.release_name
    }

    port {
      name        = "broker"
      port        = 5679
      protocol    = "TCP"
      target_port = "5679"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_deployment_v1" "python_runner" {
  metadata {
    name      = "n8n-python-runner"
    namespace = local.n8n_namespace

    labels = local.runner_labels
  }

  spec {
    replicas = 1

    selector {
      match_labels = local.runner_labels
    }

    template {
      metadata {
        labels = local.runner_labels
      }

      spec {
        service_account_name            = kubernetes_service_account_v1.runner.metadata[0].name
        automount_service_account_token = false

        security_context {
          run_as_non_root = true
          run_as_user     = 1000
          run_as_group    = 1000
        }

        container {
          name              = "python-runner"
          image             = "n8nio/runners:2.17.3"
          image_pull_policy = "IfNotPresent"

          port {
            name           = "health"
            container_port = 5680
            protocol       = "TCP"
          }

          env {
            name  = "N8N_RUNNERS_TASK_BROKER_URI"
            value = "http://${local.runner_service_name}.${local.n8n_namespace}.svc.cluster.local:5679"
          }

          env {
            name = "N8N_RUNNERS_AUTH_TOKEN"

            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.runner_auth.metadata[0].name
                key  = "N8N_RUNNERS_AUTH_TOKEN"
              }
            }
          }

          env {
            name  = "N8N_RUNNERS_LAUNCHER_HEALTH_CHECK_PORT"
            value = "5680"
          }

          env {
            name  = "N8N_RUNNERS_AUTO_SHUTDOWN_TIMEOUT"
            value = "15"
          }

          liveness_probe {
            http_get {
              path = "/healthz"
              port = "health"
            }
          }

          readiness_probe {
            http_get {
              path = "/healthz"
              port = "health"
            }
          }

          resources {
            requests = {
              cpu    = "50m"
              memory = "64Mi"
            }

            limits = {
              cpu    = "500m"
              memory = "256Mi"
            }
          }

          security_context {
            allow_privilege_escalation = false
            read_only_root_filesystem  = true
            run_as_non_root            = true
            run_as_user                = 1000
            run_as_group               = 1000

            capabilities {
              drop = ["ALL"]
            }
          }

          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }
        }

        volume {
          name = "tmp"

          empty_dir {}
        }
      }
    }
  }

  depends_on = [
    helm_release.n8n,
    kubernetes_service_v1.task_broker
  ]
}
