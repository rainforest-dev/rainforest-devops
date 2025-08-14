variable "github_token" {
  description = "GitHub Personal Access Token or GitHub App credentials"
  type        = string
  sensitive   = true
}

variable "github_repositories" {
  description = "List of GitHub repositories in format 'owner/repo'"
  type        = list(string)
}

variable "github_organizations" {
  description = "List of GitHub organizations for org-level runners"
  type        = list(string)
}

variable "runner_replicas" {
  description = "Number of runner replicas to deploy"
  type        = number
}

variable "runner_image" {
  description = "Docker image for GitHub runners"
  type        = string
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
}

variable "namespace" {
  description = "Kubernetes namespace for GitHub runners"
  type        = string
}