resource "aws_s3_bucket" "langfuse_events" {
  bucket = "${var.cluster_name}-langfuse-events-${data.aws_caller_identity.current.account_id}"

  tags = {
    Environment = var.environment
    Project     = "litellm"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "langfuse_events" {
  bucket = aws_s3_bucket.langfuse_events.id

  rule {
    id     = "expire-old-events"
    status = "Enabled"

    filter {}

    expiration {
      days = var.langfuse_event_retention_days
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "langfuse_events" {
  bucket = aws_s3_bucket.langfuse_events.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "langfuse_events" {
  bucket = aws_s3_bucket.langfuse_events.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_password" "langfuse_nextauth_secret" {
  length  = 32
  special = false
}

resource "random_password" "langfuse_salt" {
  length  = 32
  special = false
}

resource "random_password" "langfuse_clickhouse" {
  length  = 32
  special = false
}

resource "random_password" "langfuse_redis" {
  length  = 32
  special = false
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

  depends_on = [kubernetes_namespace.langfuse, kubectl_manifest.argocd_eso]
}
