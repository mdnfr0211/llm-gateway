resource "kubectl_manifest" "litellm_external_secret" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "litellm-secrets"
      namespace = "litellm"
      annotations = {
        "argocd.argoproj.io/sync-wave" = "-1"
      }
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secrets-manager"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "litellm-secrets"
        creationPolicy = "Owner"
      }
      data = [
        {
          secretKey = "LITELLM_MASTER_KEY"
          remoteRef = {
            key      = "litellm-eks/litellm-secrets"
            property = "LITELLM_MASTER_KEY"
          }
        },
        {
          secretKey = "username"
          remoteRef = {
            key      = module.rds.db_instance_master_user_secret_arn
            property = "username"
          }
        },
        {
          secretKey = "password"
          remoteRef = {
            key      = module.rds.db_instance_master_user_secret_arn
            property = "password"
          }
        },
        {
          secretKey = "LANGFUSE_PUBLIC_KEY"
          remoteRef = {
            key      = "litellm-eks/litellm-secrets"
            property = "LANGFUSE_PUBLIC_KEY"
          }
        },
        {
          secretKey = "LANGFUSE_SECRET_KEY"
          remoteRef = {
            key      = "litellm-eks/litellm-secrets"
            property = "LANGFUSE_SECRET_KEY"
          }
        },
      ]
    }
  })

  depends_on = [kubectl_manifest.argocd_eso]
}
