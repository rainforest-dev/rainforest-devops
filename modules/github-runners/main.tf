resource "kubernetes_namespace" "github_runners" {
  metadata {
    name = var.namespace
  }
}


# Repository-level runner deployments
resource "kubernetes_manifest" "repo_runner_deployment" {
  for_each = toset(var.github_repositories)
  
  manifest = {
    apiVersion = "actions.github.com/v1alpha1"
    kind       = "RunnerDeployment"
    metadata = {
      name      = "runner-${replace(each.value, "/", "-")}"
      namespace = kubernetes_namespace.github_runners.metadata[0].name
    }
    spec = {
      repository = each.value
      
      replicas = var.runner_replicas
      
      template = {
        spec = {
          image = var.runner_image
          
          labels = concat(var.runner_labels, ["repo-${replace(each.value, "/", "-")}"])
          
          resources = {
            requests = var.runner_resources.requests
            limits   = var.runner_resources.limits
          }
          
          dockerdWithinRunnerContainer = true
          
          env = [
            {
              name = "DOCKER_ENABLED"
              value = "true"
            }
          ]
          
          volumeMounts = [
            {
              name      = "docker-sock"
              mountPath = "/var/run/docker.sock"
            }
          ]
          
          volumes = [
            {
              name = "docker-sock"
              hostPath = {
                path = "/var/run/docker.sock"
                type = "Socket"
              }
            }
          ]
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.github_runners
  ]
}

# Organization-level runner deployments  
resource "kubernetes_manifest" "org_runner_deployment" {
  for_each = toset(var.github_organizations)
  
  manifest = {
    apiVersion = "actions.github.com/v1alpha1"
    kind       = "RunnerDeployment"
    metadata = {
      name      = "org-runner-${each.value}"
      namespace = kubernetes_namespace.github_runners.metadata[0].name
    }
    spec = {
      organization = each.value
      
      replicas = var.runner_replicas
      
      template = {
        spec = {
          image = var.runner_image
          
          labels = concat(var.runner_labels, ["org-${each.value}"])
          
          resources = {
            requests = var.runner_resources.requests
            limits   = var.runner_resources.limits
          }
          
          dockerdWithinRunnerContainer = true
          
          env = [
            {
              name = "DOCKER_ENABLED"
              value = "true"
            }
          ]
          
          volumeMounts = [
            {
              name      = "docker-sock"
              mountPath = "/var/run/docker.sock"
            }
          ]
          
          volumes = [
            {
              name = "docker-sock"
              hostPath = {
                path = "/var/run/docker.sock"
                type = "Socket"
              }
            }
          ]
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.github_runners
  ]
}

# Autoscalers for repository runners
resource "kubernetes_manifest" "repo_horizontal_runner_autoscaler" {
  for_each = var.runner_replicas > 1 ? toset(var.github_repositories) : []
  
  manifest = {
    apiVersion = "actions.github.com/v1alpha1"
    kind       = "HorizontalRunnerAutoscaler"
    metadata = {
      name      = "repo-autoscaler-${replace(each.value, "/", "-")}"
      namespace = kubernetes_namespace.github_runners.metadata[0].name
    }
    spec = {
      scaleTargetRef = {
        name = kubernetes_manifest.repo_runner_deployment[each.value].manifest.metadata.name
      }
      
      minReplicas = 1
      maxReplicas = var.runner_replicas * 2
      
      metrics = [
        {
          type = "TotalNumberOfQueuedAndInProgressWorkflowRuns"
          repositoryNames = [each.value]
        }
      ]
      
      scaleDownDelaySecondsAfterScaleOut = 300
      scaleUpTriggers = [
        {
          githubEvent = {
            workflowJob = {}
          }
          duration = "5m"
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.repo_runner_deployment]
}

# Autoscalers for organization runners
resource "kubernetes_manifest" "org_horizontal_runner_autoscaler" {
  for_each = var.runner_replicas > 1 ? toset(var.github_organizations) : []
  
  manifest = {
    apiVersion = "actions.github.com/v1alpha1"
    kind       = "HorizontalRunnerAutoscaler"
    metadata = {
      name      = "org-autoscaler-${each.value}"
      namespace = kubernetes_namespace.github_runners.metadata[0].name
    }
    spec = {
      scaleTargetRef = {
        name = kubernetes_manifest.org_runner_deployment[each.value].manifest.metadata.name
      }
      
      minReplicas = 1
      maxReplicas = var.runner_replicas * 2
      
      metrics = [
        {
          type = "TotalNumberOfQueuedAndInProgressWorkflowRuns"
        }
      ]
      
      scaleDownDelaySecondsAfterScaleOut = 300
      scaleUpTriggers = [
        {
          githubEvent = {
            workflowJob = {}
          }
          duration = "5m"
        }
      ]
    }
  }

  depends_on = [kubernetes_manifest.org_runner_deployment]
}