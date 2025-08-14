terraform {
  backend "local" {
    path = "terraform-dev.tfstate"
  }
}

module "github_runners_dev" {
  source = "../../"

  github_token        = var.github_token
  github_repositories  = var.github_repositories
  github_organizations = var.github_organizations
  runner_replicas     = var.runner_replicas
  runner_image        = var.runner_image
  runner_resources    = var.runner_resources
  runner_labels       = var.runner_labels
  namespace           = var.namespace
}