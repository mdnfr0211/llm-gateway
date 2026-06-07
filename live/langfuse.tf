module "s3_langfuse" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0"

  bucket           = "${var.cluster_name}-langfuse-events-${data.aws_caller_identity.current.account_id}"
  object_ownership = "BucketOwnerEnforced"

  lifecycle_rule = [
    {
      id      = "expire-old-events"
      enabled = true

      filter = {}

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
      expiration = {
        days = 60
      }
    },
  ]

  force_destroy = true

  versioning = {
    enabled = false
  }
}

resource "kubernetes_namespace" "langfuse" {
  metadata {
    name = "langfuse"
  }
}

resource "kubectl_manifest" "langfuse_external_secret" {
  yaml_body = yamlencode({
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "langfuse-secrets"
      namespace = "langfuse"
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        name = "aws-secrets-manager"
        kind = "ClusterSecretStore"
      }
      target = {
        name           = "langfuse-secrets"
        creationPolicy = "Owner"
        template = {
          mergePolicy = "Merge"
          data = {
            DATABASE_PASSWORD = "{{ .DATABASE_PASSWORD | urlquery }}"
          }
        }
      }
      data = [
        {
          secretKey = "DATABASE_PASSWORD"
          remoteRef = {
            key      = module.rds.db_instance_master_user_secret_arn
            property = "password"
          }
        },
        {
          secretKey = "NEXTAUTH_SECRET"
          remoteRef = {
            key      = "litellm-eks/langfuse-secrets"
            property = "NEXTAUTH_SECRET"
          }
        },
        {
          secretKey = "SALT"
          remoteRef = {
            key      = "litellm-eks/langfuse-secrets"
            property = "SALT"
          }
        },
        {
          secretKey = "LANGFUSE_PUBLIC_KEY"
          remoteRef = {
            key      = "litellm-eks/langfuse-secrets"
            property = "LANGFUSE_PUBLIC_KEY"
          }
        },
        {
          secretKey = "LANGFUSE_SECRET_KEY"
          remoteRef = {
            key      = "litellm-eks/langfuse-secrets"
            property = "LANGFUSE_SECRET_KEY"
          }
        },
        {
          secretKey = "CLICKHOUSE_PASSWORD"
          remoteRef = {
            key      = "litellm-eks/langfuse-secrets"
            property = "CLICKHOUSE_PASSWORD"
          }
        },
        {
          secretKey = "REDIS_PASSWORD"
          remoteRef = {
            key      = "litellm-eks/langfuse-secrets"
            property = "REDIS_PASSWORD"
          }
        },
        {
          secretKey = "INIT_USER_EMAIL"
          remoteRef = {
            key      = "litellm-eks/langfuse-secrets"
            property = "INIT_USER_EMAIL"
          }
        },
        {
          secretKey = "INIT_USER_PASSWORD"
          remoteRef = {
            key      = "litellm-eks/langfuse-secrets"
            property = "INIT_USER_PASSWORD"
          }
        },
      ]
    }
  })

  depends_on = [
    kubernetes_namespace.langfuse,
    kubectl_manifest.argocd_eso,
  ]
}
