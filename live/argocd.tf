resource "kubectl_manifest" "argocd_eso" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "eso-resources"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = local.git_repo
        targetRevision = local.git_branch
        path           = "k8s/eso"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "external-secrets"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  })

  depends_on = [module.eks_blueprints_addons]
}

resource "kubectl_manifest" "argocd_langfuse" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "langfuse"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      sources = [
        {
          repoURL        = "https://langfuse.github.io/langfuse-k8s"
          chart          = "langfuse"
          targetRevision = "1.5.33"
          helm = {
            valueFiles = ["$values/k8s/langfuse/values.yaml"]
            parameters = [
              {
                name  = "s3.bucket"
                value = aws_s3_bucket.langfuse_events.id
              },
              {
                name  = "postgresql.host"
                value = module.rds.db_instance_address
              }
            ]
          }
        },
        {
          repoURL        = local.git_repo
          targetRevision = local.git_branch
          ref            = "values"
        },
      ]
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "langfuse"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  })

  depends_on = [module.eks_blueprints_addons, kubectl_manifest.argocd_eso, kubectl_manifest.langfuse_external_secret]
}

resource "kubectl_manifest" "argocd_litellm" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "litellm"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      sources = [
        {
          repoURL        = "oci://docker.litellm.ai/berriai/litellm-helm"
          targetRevision = "1.86.2"
          path           = "."
          helm = {
            valueFiles = ["$values/k8s/litellm/values.yaml"]
          }
        },
        {
          repoURL        = local.git_repo
          targetRevision = local.git_branch
          ref            = "values"
        }
      ]
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "litellm"
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  })

  depends_on = [module.eks_blueprints_addons, kubectl_manifest.argocd_eso, kubectl_manifest.litellm_external_secret]
}
