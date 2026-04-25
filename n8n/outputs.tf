output "n8n_namespace" {
  description = "Kubernetes namespace where n8n is installed."
  value       = local.n8n_namespace
}

output "n8n_release_name" {
  description = "Helm release name for n8n."
  value       = helm_release.n8n.name
}

output "n8n_url" {
  description = "Public n8n URL."
  value       = "${var.n8n_protocol}://${var.n8n_host}"
}
