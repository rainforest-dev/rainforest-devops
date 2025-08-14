resource "kubernetes_namespace" "actions_runner_system" {
  metadata {
    name = "actions-runner-system"
  }
}

# GitHub PAT secret - simplified approach
resource "kubernetes_secret" "github_token" {
  metadata {
    name      = "github-token"
    namespace = kubernetes_namespace.actions_runner_system.metadata[0].name
  }

  data = {
    github_token = var.github_token
  }

  type = "Opaque"
}

resource "helm_release" "actions_runner_controller" {
  name       = "arc"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = "0.9.3"
  namespace  = kubernetes_namespace.actions_runner_system.metadata[0].name

  wait = true
  timeout = 600

  depends_on = [kubernetes_secret.github_token]
}