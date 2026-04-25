output "db_database_name" {
  description = "PostgreSQL database name initialized for n8n."
  value       = var.db_name
}

output "db_host" {
  description = "PostgreSQL service DNS name used by n8n."
  value       = local.db_host
}

output "db_password_secret_name" {
  description = "Kubernetes Secret name that stores the n8n database password."
  value       = kubernetes_secret_v1.database_application.metadata[0].name
}

output "db_port" {
  description = "PostgreSQL service port used by n8n."
  value       = local.db_port
}

output "db_user" {
  description = "PostgreSQL username initialized for n8n."
  value       = var.db_user
}

output "n8n_namespace" {
  description = "Kubernetes namespace where n8n database credentials are available."
  value       = kubernetes_namespace_v1.application.metadata[0].name
}

output "application_database_name" {
  description = "Application database name initialized in PostgreSQL."
  value       = var.db_name
}

output "application_database_secret_name" {
  description = "Kubernetes Secret name that stores the application database password."
  value       = kubernetes_secret_v1.database_application.metadata[0].name
}

output "application_database_user" {
  description = "Application database user initialized in PostgreSQL."
  value       = var.db_user
}

output "application_namespace" {
  description = "Kubernetes namespace where application database credentials are available."
  value       = kubernetes_namespace_v1.application.metadata[0].name
}

output "database_init_release_name" {
  description = "Helm release name for the database initialization chart."
  value       = helm_release.database_init.name
}
