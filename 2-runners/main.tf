terraform {
  required_version = ">= 1.0"
  
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.20"
    }
  }
  
  backend "local" {
    path = "runners.tfstate"
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "vault" {
  address = "http://vault.vault.svc.cluster.local:8200"
  token   = var.vault_dev_token
}

# Verify infrastructure is ready
data "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

data "kubernetes_namespace" "arc" {
  metadata {
    name = "actions-runner-system"
  }
}

data "kubernetes_resources" "arc_crds" {
  api_version    = "apiextensions.k8s.io/v1"
  kind           = "CustomResourceDefinition"
  field_selector = "metadata.name=runnerdeployments.actions.github.com"
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
  
  # Ensure infrastructure is ready
  depends_on = [
    data.kubernetes_namespace.vault,
    data.kubernetes_namespace.arc,
    data.kubernetes_resources.arc_crds
  ]
}