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

# Shared security group for inter-service communication
# All ECS services will be added to this group to enable service-to-service calls
resource "aws_security_group" "ecs_services" {
  name        = "${local.project}-${local.environment}-ecs-services"
  description = "Shared security group for ECS inter-service communication"
  vpc_id      = module.vpc.vpc_id

  # Allow inbound traffic from any service in this security group
  ingress {
    description = "Allow inter-service communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.project}-${local.environment}-ecs-services"
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

# ============================================================
# SERVICE DISCOVERY NAMESPACE
# ============================================================
# Private DNS namespace for inter-service communication
# Services will be accessible at: <service-name>.staging.generic-gha.local

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "${local.environment}.${local.project}.local"
  description = "Service discovery namespace for ${local.project} ${local.environment}"
  vpc         = module.vpc.vpc_id

  tags = {
    Name        = "${local.project}-${local.environment}-service-discovery"
    Environment = local.environment
  }
}
