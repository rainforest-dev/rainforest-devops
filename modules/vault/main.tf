resource "kubernetes_namespace" "vault" {
  metadata {
    name = "vault"
  }
}

resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.25.0"
  namespace  = kubernetes_namespace.vault.metadata[0].name

  values = [
    yamlencode({
      server = {
        dev = {
          enabled = true
          devRootToken = var.vault_root_token
        }
        dataStorage = {
          enabled = true
          size = "1Gi"
          storageClass = null
        }
        resources = {
          requests = {
            memory = "256Mi"
            cpu    = "250m"
          }
          limits = {
            memory = "512Mi"
            cpu    = "500m"
          }
        }
      }
      ui = {
        enabled = true
        serviceType = "ClusterIP"
      }
      injector = {
        enabled = false
      }
    })
  ]

  wait = true
  timeout = 300
}

# Vault policy for GitHub secrets
resource "vault_policy" "github_secrets" {
  name = "github-secrets"

  policy = <<EOT
path "secret/data/github/*" {
  capabilities = ["read"]
}
path "secret/metadata/github/*" {
  capabilities = ["read", "list"]
}
EOT

  depends_on = [helm_release.vault]
}

# Kubernetes auth method
resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  
  depends_on = [helm_release.vault]
}

# Kubernetes auth configuration will be done post-deployment
# resource "vault_kubernetes_auth_backend_config" "kubernetes" {
#   backend                = vault_auth_backend.kubernetes.path
#   kubernetes_host        = "https://kubernetes.default.svc:443"
#   kubernetes_ca_cert     = base64decode(data.kubernetes_secret_v1.vault_token.data["ca.crt"])
#   token_reviewer_jwt     = data.kubernetes_secret_v1.vault_token.data.token
#   issuer                 = "https://kubernetes.default.svc.cluster.local"
#   disable_iss_validation = true
# }

# Auth role configuration will be done post-deployment
# resource "vault_kubernetes_auth_backend_role" "github_runners" {
#   backend                          = vault_auth_backend.kubernetes.path
#   role_name                        = "github-runners"
#   bound_service_account_names      = ["actions-runner-controller"]
#   bound_service_account_namespaces = ["actions-runner-system"]
#   token_ttl                        = 3600
#   token_policies                   = ["github-secrets"]
# }

# Note: Service account is created by Helm chart
# We'll configure Kubernetes auth after Vault is running

# GitHub PAT secret
resource "vault_kv_secret_v2" "github_pat" {
  mount = "secret"
  name  = "github/pat"
  
  data_json = jsonencode({
    token = var.github_token
  })

  depends_on = [helm_release.vault]
}