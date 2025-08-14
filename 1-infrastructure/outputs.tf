output "cert_manager_namespace" {
  description = "Namespace where cert-manager is deployed"
  value       = module.cert_manager.namespace
}

output "arc_namespace" {
  description = "Namespace where Actions Runner Controller is deployed"
  value       = module.actions_runner_controller.namespace
}

output "arc_status" {
  description = "Status of Actions Runner Controller deployment"
  value       = module.actions_runner_controller.status
}