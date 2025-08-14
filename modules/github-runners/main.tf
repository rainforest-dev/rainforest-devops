resource "kubernetes_namespace" "github_runners" {
  metadata {
    name = var.namespace
  }
}

# GitHub PAT secret for runner scale sets
resource "kubernetes_secret" "github_token" {
  metadata {
    name      = "github-token"
    namespace = kubernetes_namespace.github_runners.metadata[0].name
  }

  data = {
    github_token = var.github_token
  }

  type = "Opaque"
}

# Organization-level runner scale sets using official GitHub ARC
resource "helm_release" "org_runner_scale_set" {
  for_each = toset(var.github_organizations)
  
  name       = "arc-runner-set-${each.value}"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = "0.9.3"
  namespace  = kubernetes_namespace.github_runners.metadata[0].name

  values = [
    yamlencode({
      githubConfigUrl    = "https://github.com/${each.value}"
      githubConfigSecret = "github-token"
      
      minRunners = 1
      maxRunners = var.runner_replicas * 2
      
      runnerScaleSetName = "arc-runner-set-${each.value}"
      
      template = {
        spec = {
          containers = [{
            name  = "runner"
            image = var.runner_image
            resources = var.runner_resources
          }]
        }
      }
      
      controllerServiceAccount = {
        namespace = "actions-runner-system"
        name      = "arc-gha-rs-controller"
      }
    })
  ]

  wait = true
  timeout = 600

  depends_on = [
    kubernetes_namespace.github_runners,
    kubernetes_secret.github_token
  ]
}

# Repository-level runner scale sets
resource "helm_release" "repo_runner_scale_set" {
  for_each = toset(var.github_repositories)
  
  name       = "arc-runner-set-${replace(each.value, "/", "-")}"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = "0.9.3"
  namespace  = kubernetes_namespace.github_runners.metadata[0].name

  values = [
    yamlencode({
      githubConfigUrl    = "https://github.com/${each.value}"
      githubConfigSecret = "github-token"
      
      minRunners = 1
      maxRunners = var.runner_replicas * 2
      
      runnerScaleSetName = "arc-runner-set-${replace(each.value, "/", "-")}"
      
      template = {
        spec = {
          containers = [{
            name  = "runner"
            image = var.runner_image
            resources = var.runner_resources
          }]
        }
      }
      
      controllerServiceAccount = {
        namespace = "actions-runner-system"
        name      = "arc-gha-rs-controller"
      }
    })
  ]

  wait = true
  timeout = 600

  depends_on = [
    kubernetes_namespace.github_runners,
    kubernetes_secret.github_token
  ]
}