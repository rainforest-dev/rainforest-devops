resource "kubernetes_namespace" "actions_runner_system" {
  metadata {
    name = "actions-runner-system"
  }
}

# Vault secret injection using annotations
resource "kubernetes_secret" "github_token" {
  metadata {
    name      = "github-token"
    namespace = kubernetes_namespace.actions_runner_system.metadata[0].name
    annotations = {
      "vault.hashicorp.com/agent-inject" = "true"
      "vault.hashicorp.com/agent-inject-secret-github_token" = "secret/data/github/pat"
      "vault.hashicorp.com/agent-inject-template-github_token" = <<EOF
{{- with secret "secret/data/github/pat" -}}
{{ .Data.data.token }}
{{- end -}}
EOF
      "vault.hashicorp.com/role" = "github-runners"
    }
  }

  data = {
    github_token = "placeholder" # Will be replaced by Vault injection
  }

  type = "Opaque"
}

# Data source to read from Vault
data "vault_kv_secret_v2" "github_pat" {
  mount = "secret"
  name  = "github/pat"
}

# Update the secret with actual Vault data
resource "kubernetes_secret" "github_token_vault" {
  metadata {
    name      = "github-token-vault"
    namespace = kubernetes_namespace.actions_runner_system.metadata[0].name
  }

  data = {
    github_token = data.vault_kv_secret_v2.github_pat.data["token"]
  }

  type = "Opaque"
}

resource "helm_release" "actions_runner_controller" {
  name       = "actions-runner-controller"
  repository = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart      = "actions-runner-controller"
  version    = "0.23.7"
  namespace  = kubernetes_namespace.actions_runner_system.metadata[0].name

  set {
    name  = "authSecret.create"
    value = "false"
  }

  set {
    name  = "authSecret.name"
    value = kubernetes_secret.github_token_vault.metadata[0].name
  }

  set {
    name  = "authSecret.github_token"
    value = "github_token"
  }

  set {
    name  = "replicaCount"
    value = "1"
  }

  set {
    name  = "image.tag"
    value = "v0.27.4"
  }

  wait = true
  timeout = 600

  depends_on = [kubernetes_secret.github_token_vault]
}