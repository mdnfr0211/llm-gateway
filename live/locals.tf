locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)

  langfuse_db = "langfuse"
  litellm_db  = "litellm"

  db_credentials = jsondecode(data.aws_secretsmanager_secret_version.db_credential.secret_string)
  db_username    = local.db_credentials["username"]
  db_password    = local.db_credentials["password"]
  db_host        = module.rds.db_instance_address

  git_repo   = "https://github.com/mdnfr0211/llm-gateway"
  git_branch = "main"
}
