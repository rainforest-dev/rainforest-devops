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
    path = "infrastructure.tfstate"
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

module "cert_manager" {
  source = "../modules/cert-manager"
}

module "actions_runner_controller" {
  source = "../modules/actions-runner-controller"
  
  depends_on = [module.cert_manager]
  
  github_token = var.github_token
}