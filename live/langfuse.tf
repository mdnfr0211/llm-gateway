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

    filter {} # Apply to all objects

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

# random_password resources are kept because their outputs feed into secrets.tf
# (AWS Secrets Manager secret versions for langfuse-secrets and langfuse-litellm-keys).
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
