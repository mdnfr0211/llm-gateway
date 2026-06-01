# RDS PostgreSQL (Free Tier compatible)
module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "${var.cluster_name}-db"

  engine               = "postgres"
  engine_version       = "18.3"
  family               = "postgres18"
  major_engine_version = "18"
  instance_class       = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 20 # Disable autoscaling for Free Tier

  db_name  = var.db_name
  username = var.db_master_username
  port     = 5432

  # Secrets Manager for password
  manage_master_user_password = true

  # Network
  db_subnet_group_name   = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Free Tier settings - disable all extras
  backup_retention_period = 0 # Disable automated backups
  multi_az                = false
  deletion_protection     = false
  skip_final_snapshot     = true
  storage_encrypted       = false # Free Tier may not support encryption
  publicly_accessible     = false

  # Disable Performance Insights and Enhanced Monitoring
  performance_insights_enabled = false
  monitoring_interval          = 0

  # Disable IAM auth (simplify)
  iam_database_authentication_enabled = false

  tags = {
    Environment = var.environment
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "${var.cluster_name}-rds-"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
    description     = "PostgreSQL from EKS nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-rds"
  }
}
