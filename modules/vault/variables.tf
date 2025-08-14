variable "vault_root_token" {
  description = "Vault root token for dev mode"
  type        = string
  default     = "dev-root-token-change-me"
  sensitive   = true
}

variable "github_token" {
  description = "GitHub Personal Access Token to store in Vault"
  type        = string
  sensitive   = true
}