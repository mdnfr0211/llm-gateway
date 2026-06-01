data "aws_caller_identity" "current" {}

data "aws_secretsmanager_secret_version" "db_credential" {
  secret_id = module.rds.db_instance_master_user_secret_arn
}
