variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
}

variable "node_instance_types" {
  description = "Instance types for the default managed node group"
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired number of nodes in the default node group"
  type        = number
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_master_username" {
  description = "Master username for RDS"
  type        = string
}

variable "litellm_db_secret_name" {
  description = "Secrets Manager secret name containing LiteLLM DB connection (keys: host, port, username, password, dbname)"
  type        = string
}

variable "langfuse_db_secret_name" {
  description = "Secrets Manager secret name containing Langfuse DB connection (keys: host, port, username, password, dbname)"
  type        = string
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
