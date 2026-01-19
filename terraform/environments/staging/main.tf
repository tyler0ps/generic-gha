data "aws_caller_identity" "current" {}

# VPC
module "vpc" {
  source = "../../modules/vpc"

  name               = "${local.project}-${local.environment}"
  environment        = local.environment
  cidr               = "10.0.0.0/16"
  azs                = local.azs
  single_nat_gateway = true # Cost saving for staging
  enable_nat_gateway = true # Required for ECS to pull images

}

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

# ECS Cluster
module "ecs_cluster" {
  source = "../../modules/ecs-cluster"

  name                      = "${local.project}-${local.environment}"
  environment               = local.environment
  enable_container_insights = false # Cost saving
  use_spot                  = true  # Cost saving
}

# ALB
module "alb" {
  source = "../../modules/alb"

  name                       = "${local.project}-${local.environment}"
  environment                = local.environment
  vpc_id                     = module.vpc.vpc_id
  public_subnets             = module.vpc.public_subnets
  enable_deletion_protection = false # Easy destruction
}

# RDS PostgreSQL
module "rds" {
  source = "../../modules/rds"

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
