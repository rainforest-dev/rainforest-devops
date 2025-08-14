output "cert_manager_namespace" {
  description = "Namespace where cert-manager is deployed"
  value       = module.cert_manager.namespace
}

output "arc_namespace" {
  description = "Namespace where Actions Runner Controller is deployed"
  value       = module.actions_runner_controller.namespace
}

output "runners_namespace" {
  description = "Namespace where GitHub runners are deployed"
  value       = module.github_runners.namespace
}

output "repo_runner_deployments" {
  description = "Names of repository RunnerDeployment resources"
  value       = module.github_runners.repo_deployment_names
}

output "org_runner_deployments" {
  description = "Names of organization RunnerDeployment resources"
  value       = module.github_runners.org_deployment_names
}