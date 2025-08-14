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
  default     = 2
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

variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

