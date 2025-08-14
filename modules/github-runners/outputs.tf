output "namespace" {
  description = "Namespace where GitHub runners are deployed"
  value       = kubernetes_namespace.github_runners.metadata[0].name
}

output "repo_scale_set_names" {
  description = "Names of repository RunnerScaleSet Helm releases"
  value       = [for k, v in helm_release.repo_runner_scale_set : v.name]
}

output "org_scale_set_names" {
  description = "Names of organization RunnerScaleSet Helm releases" 
  value       = [for k, v in helm_release.org_runner_scale_set : v.name]
}