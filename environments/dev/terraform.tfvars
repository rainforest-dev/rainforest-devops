# GitHub configuration - specify repositories and/or organizations
github_repositories = [
  # Add specific repositories if needed
]
github_organizations = [
  "8am-tech"
]

# Runner configuration
runner_replicas = 2
runner_image = "sumologic/github-action-runner:latest"
runner_labels = ["self-hosted", "linux", "x64", "dev"]

# Resource allocation for dev environment
runner_resources = {
  requests = {
    cpu    = "100m"
    memory = "256Mi"
  }
  limits = {
    cpu    = "1000m"
    memory = "1Gi"
  }
}

# Namespace
namespace = "github-runners-dev"