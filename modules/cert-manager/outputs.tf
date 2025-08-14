output "namespace" {
  description = "Namespace where cert-manager is deployed"
  value       = helm_release.cert_manager.namespace
}

output "status" {
  description = "Status of cert-manager deployment"
  value       = helm_release.cert_manager.status
}