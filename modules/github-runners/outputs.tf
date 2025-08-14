output "namespace" {
  description = "Namespace where GitHub runners are deployed"
  value       = kubernetes_namespace.github_runners.metadata[0].name
}

output "repo_deployment_names" {
  description = "Names of repository RunnerDeployment resources"
  value       = [for k, v in kubernetes_manifest.repo_runner_deployment : v.manifest.metadata.name]
}

output "org_deployment_names" {
  description = "Names of organization RunnerDeployment resources" 
  value       = [for k, v in kubernetes_manifest.org_runner_deployment : v.manifest.metadata.name]
}

output "autoscaler_enabled" {
  description = "Whether horizontal autoscaler is enabled"
  value       = var.runner_replicas > 1
}