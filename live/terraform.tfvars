aws_region          = "ap-southeast-1"
environment         = "production"
cluster_name        = "litellm-eks"
vpc_cidr            = "10.0.0.0/16"
cluster_version     = "1.35"
node_instance_types = ["c7i-flex.large"]
node_desired_size   = 2
db_instance_class   = "db.t3.micro"
db_name             = "litellm"
db_master_username  = "litellm_admin"


litellm_db_secret_name  = "litellm/database"
langfuse_db_secret_name = "langfuse/database"

langfuse_init_user_email    = "admin@example.com"
langfuse_init_user_name     = "Admin"
langfuse_init_user_password = "changeme123!"
