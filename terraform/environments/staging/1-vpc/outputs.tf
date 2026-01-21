# ============================================================
# VPC LAYER OUTPUTS
# ============================================================
# These outputs are consumed by other layers via remote state

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "private_route_table_ids" {
  description = "Private route table IDs"
  value       = module.vpc.private_route_table_ids
}

# Common Values
output "region" {
  description = "AWS region"
  value       = local.region
}

output "environment" {
  description = "Environment name"
  value       = local.environment
}

output "project" {
  description = "Project name"
  value       = local.project
}

output "azs" {
  description = "Availability zones"
  value       = local.azs
}
