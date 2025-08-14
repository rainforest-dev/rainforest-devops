# GitHub configuration - 8am-tech organization
github_repositories = [
  # Add specific repositories if needed
  # "8am-tech/specific-repo"
]

github_organizations = [
  "8am-tech"
]

# Runner configuration
runner_replicas = 5
runner_image = "sumologic/github-action-runner:latest"
runner_labels = ["self-hosted", "linux", "x64", "prod"]

# Resource allocation for production
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
namespace = "github-runners"