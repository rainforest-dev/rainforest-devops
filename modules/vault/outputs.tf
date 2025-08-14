output "vault_namespace" {
  description = "Namespace where Vault is deployed"
  value       = kubernetes_namespace.vault.metadata[0].name
}

output "vault_service_name" {
  description = "Vault service name"
  value       = "${helm_release.vault.name}.${kubernetes_namespace.vault.metadata[0].name}.svc.cluster.local"
}

output "vault_url" {
  description = "Vault service URL"
  value       = "http://${helm_release.vault.name}.${kubernetes_namespace.vault.metadata[0].name}.svc.cluster.local:8200"
}

output "kubernetes_auth_path" {
  description = "Kubernetes auth backend path"
  value       = vault_auth_backend.kubernetes.path
}