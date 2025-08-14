variable "github_token" {
  description = "GitHub Personal Access Token"
  type        = string
  sensitive   = true
}

variable "vault_dev_token" {
  description = "Vault development root token"
  type        = string
  default     = "dev-root-token-change-me"
  sensitive   = true
}