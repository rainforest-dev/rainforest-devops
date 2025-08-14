# GitHub configuration - 8am-tech organization
github_repositories = [
  # Add specific repositories if needed
]
github_organizations = [
  # "8am-tech"  # Will enable after ARC is deployed
]

# Runner configuration
runner_replicas = 5
runner_image = "sumologic/github-action-runner:latest"
runner_labels = ["self-hosted", "linux", "x64", "prod"]

# Resource allocation for production environment
runner_resources = {
  requests = {
    cpu    = "500m"
    memory = "1Gi"
  }
  limits = {
    cpu    = "2000m"
    memory = "4Gi"
  }
}

# Namespace
namespace = "github-runners-prod"