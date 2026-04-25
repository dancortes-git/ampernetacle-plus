output "postgresql_namespace" {
  description = "Namespace where PostgreSQL is installed."
  value       = kubernetes_namespace_v1.postgresql.metadata[0].name
}

output "postgresql_release_name" {
  description = "Helm release name for PostgreSQL."
  value       = helm_release.postgresql.name
}

output "postgresql_secret_name" {
  description = "Kubernetes Secret name that stores the PostgreSQL admin password."
  value       = kubernetes_secret_v1.postgresql.metadata[0].name
}
