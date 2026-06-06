variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "litellm-eks"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "node_instance_types" {
  description = "Instance types for the default managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of nodes in the default node group"
  type        = number
  default     = 2
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "18.3"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "postgres"
}

variable "db_master_username" {
  description = "Master username for RDS"
  type        = string
  default     = "root"
}

variable "langfuse_event_retention_days" {
  description = "Number of days to retain Langfuse events in S3"
  type        = number
  default     = 90
}

variable "litellm_db_secret_name" {
  description = "Secrets Manager secret name containing LiteLLM DB connection (keys: host, port, username, password, dbname)"
  type        = string
  default     = "litellm/database"
}

variable "langfuse_db_secret_name" {
  description = "Secrets Manager secret name containing Langfuse DB connection (keys: host, port, username, password, dbname)"
  type        = string
  default     = "langfuse/database"
}

# litellm_master_key, langfuse_init_user_email, langfuse_init_user_name, and
# langfuse_init_user_password have been moved to AWS Secrets Manager (secrets.tf).
# They are still referenced as TF variables so the secrets.tf can populate SM.
variable "litellm_master_key" {
  description = "LiteLLM master/admin key (written to AWS Secrets Manager)"
  type        = string
  sensitive   = true
  default     = "sk-tREjbbyrLevnouz9zsRo"
}

variable "langfuse_init_user_email" {
  description = "Email for the initial Langfuse admin user (written to AWS Secrets Manager)"
  type        = string
}

variable "langfuse_init_user_name" {
  description = "Display name for the initial Langfuse admin user (hardcoded in k8s/langfuse/values.yaml)"
  type        = string
}

variable "langfuse_init_user_password" {
  description = "Password for the initial Langfuse admin user (written to AWS Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "github_org" {
  description = "GitHub organization for OIDC"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name for OIDC"
  type        = string
  default     = ""
}
