# ============================================================
# DATA SOURCES
# ============================================================
# Import outputs from infrastructure layer via remote state

data "aws_caller_identity" "current" {}

# Import infrastructure layer outputs
data "terraform_remote_state" "infrastructure" {
  backend = "s3"
  config = {
    bucket = "generic-gha-terraform-state"
    key    = "staging/infrastructure/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

# ECR repositories (from global layer)
data "aws_ecr_repository" "api_golang" {
  name = "${local.project}/api-golang"
}

data "aws_ecr_repository" "api_node" {
  name = "${local.project}/api-node"
}

data "aws_ecr_repository" "api_golang_migrator" {
  name = "${local.project}/api-golang-migrator"
}

# Convenience locals for cleaner code
locals {
  # Infrastructure outputs
  vpc_id                           = data.terraform_remote_state.infrastructure.outputs.vpc_id
  public_subnets                   = data.terraform_remote_state.infrastructure.outputs.public_subnets
  private_subnets                  = data.terraform_remote_state.infrastructure.outputs.private_subnets
  db_access_security_group_id      = data.terraform_remote_state.infrastructure.outputs.db_access_security_group_id
  ecs_services_security_group_id   = data.terraform_remote_state.infrastructure.outputs.ecs_services_security_group_id
  rds_connection_string_ssm_arn    = data.terraform_remote_state.infrastructure.outputs.rds_connection_string_ssm_arn
  rds_security_group_id            = data.terraform_remote_state.infrastructure.outputs.rds_security_group_id
  service_discovery_namespace_id   = data.terraform_remote_state.infrastructure.outputs.service_discovery_namespace_id
  service_discovery_namespace_name = data.terraform_remote_state.infrastructure.outputs.service_discovery_namespace_name
}
