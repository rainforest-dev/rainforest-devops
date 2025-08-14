module "vault" {
  source = "./modules/vault"
  
  github_token = var.github_token
}

module "cert_manager" {
  source = "./modules/cert-manager"
}

module "actions_runner_controller" {
  source = "./modules/actions-runner-controller"
  
  depends_on = [module.cert_manager]
  
  github_token = var.github_token
}

module "github_runners" {
  source = "./modules/github-runners"
  
  depends_on = [module.actions_runner_controller]
  
  github_repositories = var.github_repositories
  github_organizations = var.github_organizations
  runner_replicas = var.runner_replicas
  runner_image = var.runner_image
  runner_resources = var.runner_resources
  runner_labels = var.runner_labels
  namespace = var.namespace
  arc_deployment_ready = module.actions_runner_controller.deployment_ready
}