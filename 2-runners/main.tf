terraform {
  required_version = ">= 1.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
  
  backend "local" {
    path = "runners.tfstate"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Verify infrastructure is ready
data "kubernetes_namespace" "arc" {
  metadata {
    name = "actions-runner-system"
  }
}

module "github_runners" {
  source = "../modules/github-runners"
  
  github_repositories = var.github_repositories
  github_organizations = var.github_organizations
  runner_replicas = var.runner_replicas
  runner_image = var.runner_image
  runner_resources = var.runner_resources
  runner_labels = var.runner_labels
  namespace = var.namespace
  github_token = var.github_token
  
  # Ensure infrastructure is ready
  depends_on = [
    data.kubernetes_namespace.arc
  ]
}