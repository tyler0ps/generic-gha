# ============================================================
# DATABASE LAYER
# ============================================================
# RDS PostgreSQL, security groups, and service discovery
# Depends on: VPC layer (1-vpc)

# ============================================================
# SECURITY GROUPS
# ============================================================

# Shared security group for services that need database access
# This breaks the cycle between services and RDS
resource "aws_security_group" "db_access" {
  name        = "${local.project}-${local.environment}-db-access"
  description = "Security group for services that need database access"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

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
  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnets

  # Use shared db_access security group to break cycle
  allowed_security_groups = [aws_security_group.db_access.id]

  instance_class          = "db.t3.micro" # Smallest for testing
  deletion_protection     = false         # Easy destruction
  skip_final_snapshot     = true          # Easy destruction
  backup_retention_period = 0             # No backups for testing
}
