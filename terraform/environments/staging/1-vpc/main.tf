# ============================================================
# VPC LAYER
# ============================================================
# Base networking infrastructure for ECS services
# This VPC hosts RDS and ECS services

module "vpc" {
  source = "../../../modules/vpc"

  name               = "${local.project}-${local.environment}"
  environment        = local.environment
  cidr               = "10.0.0.0/16"
  azs                = local.azs
  single_nat_gateway = true # Cost saving for staging
  enable_nat_gateway = false # Required for ECS to pull images
}
