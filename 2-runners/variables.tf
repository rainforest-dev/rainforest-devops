variable "github_repositories" {
  description = "List of GitHub repositories in format 'owner/repo'"
  type        = list(string)
  default     = []
}

variable "github_organizations" {
  description = "List of GitHub organizations for org-level runners"
  type        = list(string)
  default     = []
}

variable "runner_replicas" {
  description = "Number of runner replicas to deploy"
  type        = number
  default     = 3
}

variable "runner_image" {
  description = "Docker image for GitHub runners"
  type        = string
  default     = "sumologic/github-action-runner:latest"
}

variable "runner_resources" {
  description = "Resource requests and limits for runners"
  type = object({
    requests = object({
      cpu    = string
      memory = string
    })
    limits = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    requests = {
      cpu    = "500m"
      memory = "1Gi"
    }
    limits = {
      cpu    = "2000m"
      memory = "4Gi"
    }
  }
}

variable "runner_labels" {
  description = "Labels to assign to runners"
  type        = list(string)
  default     = ["self-hosted", "linux", "x64"]
}

variable "namespace" {
  description = "Kubernetes namespace for GitHub runners"
  type        = string
  default     = "github-runners"
}

variable "vault_dev_token" {
  description = "Vault development root token"
  type        = string
  default     = "dev-root-token-change-me"
  sensitive   = true
}