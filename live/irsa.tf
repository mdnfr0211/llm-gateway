resource "aws_iam_role" "litellm_bedrock" {
  name = "${var.cluster_name}-litellm-bedrock"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "litellm_bedrock" {
  role       = aws_iam_role.litellm_bedrock.name
  policy_arn = aws_iam_policy.litellm_bedrock.arn
}

resource "aws_iam_policy" "litellm_bedrock" {
  name = "${var.cluster_name}-litellm-bedrock"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:InvokeFoundationModel",
        ]
        Resource = [
          "arn:aws:bedrock:::foundation-model/amazon.nova-2-lite-v1:0",
          "arn:aws:bedrock:ap-southeast-1::foundation-model/amazon.nova-2-lite-v1:0",
          "arn:aws:bedrock:ap-southeast-1:${data.aws_caller_identity.current.account_id}:inference-profile/global.amazon.nova-2-lite-v1:0"
        ]
      }
    ]
  })
}

resource "aws_eks_pod_identity_association" "litellm" {
  cluster_name    = module.eks.cluster_name
  namespace       = "litellm"
  service_account = "litellm"
  role_arn        = aws_iam_role.litellm_bedrock.arn
}

resource "aws_iam_role" "langfuse_s3" {
  name = "${var.cluster_name}-langfuse-s3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "langfuse_s3" {
  role       = aws_iam_role.langfuse_s3.name
  policy_arn = aws_iam_policy.langfuse_s3.arn
}

resource "aws_iam_policy" "langfuse_s3" {
  name = "${var.cluster_name}-langfuse-s3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          aws_s3_bucket.langfuse_events.arn,
          "${aws_s3_bucket.langfuse_events.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_eks_pod_identity_association" "langfuse" {
  cluster_name    = module.eks.cluster_name
  namespace       = "langfuse"
  service_account = "langfuse"
  role_arn        = aws_iam_role.langfuse_s3.arn
}

resource "aws_iam_role" "eso" {
  name = "${var.cluster_name}-eso"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "pods.eks.amazonaws.com"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }]
  })
}

resource "aws_iam_policy" "eso" {
  name        = "${var.cluster_name}-eso"
  description = "Allow ESO to read secrets from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:ap-southeast-1:${data.aws_caller_identity.current.account_id}:secret:litellm-eks/langfuse-secrets-LnoRLt",
          "arn:aws:secretsmanager:ap-southeast-1:${data.aws_caller_identity.current.account_id}:secret:litellm-eks/litellm-secrets-sk2IOS",
          module.rds.db_instance_master_user_secret_arn,
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eso" {
  role       = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso.arn
}

resource "aws_eks_pod_identity_association" "eso" {
  cluster_name    = module.eks.cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets-sa"
  role_arn        = aws_iam_role.eso.arn
}
