# ============================================================
# INFRASTRUCTURE LAYER
# ============================================================
# Long-lived resources: VPC, RDS, Security Groups
# Apply once and keep running

data "aws_caller_identity" "current" {}

# ============================================================
# VPC
# ============================================================

module "vpc" {
  source = "../../../modules/vpc"

  name               = "${local.project}-${local.environment}"
  environment        = local.environment
  cidr               = "10.0.0.0/16"
  azs                = local.azs
  single_nat_gateway = true # Cost saving for staging
  enable_nat_gateway = true # Required for ECS to pull images
}

# ============================================================
# SECURITY GROUPS
# ============================================================

# Shared security group for services that need database access
# This breaks the cycle between services and RDS
resource "aws_security_group" "db_access" {
  name        = "${local.project}-${local.environment}-db-access"
  description = "Security group for services that need database access"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.project}-${local.environment}-db-access"
    Environment = local.environment
  }
}

# ============================================================
# RDS POSTGRESQL
# ============================================================

module "rds" {
  source = "../../../modules/rds"

  name            = "postgres"
  environment     = local.environment
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  # Use shared db_access security group to break cycle
  allowed_security_groups = [aws_security_group.db_access.id]

  instance_class          = "db.t3.micro" # Smallest for testing
  deletion_protection     = false         # Easy destruction
  skip_final_snapshot     = true          # Easy destruction
  backup_retention_period = 0             # No backups for testing
}
