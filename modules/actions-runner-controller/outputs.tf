output "namespace" {
  description = "Namespace where Actions Runner Controller is deployed"
  value       = kubernetes_namespace.actions_runner_system.metadata[0].name
}

output "secret_name" {
  description = "Name of the GitHub token secret"
  value       = kubernetes_secret.github_token.metadata[0].name
}

output "status" {
  description = "Status of Actions Runner Controller deployment"
  value       = helm_release.actions_runner_controller.status
}

