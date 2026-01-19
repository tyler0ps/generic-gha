# ============================================================
# INFRASTRUCTURE OUTPUTS
# ============================================================
# These outputs are consumed by the compute layer via remote state

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

# Security Group Outputs
output "db_access_security_group_id" {
  description = "Security group ID for database access"
  value       = aws_security_group.db_access.id
}

# RDS Outputs
output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.endpoint
}

output "rds_address" {
  description = "RDS hostname"
  value       = module.rds.address
}

output "rds_port" {
  description = "RDS port"
  value       = module.rds.port
}

output "rds_database_name" {
  description = "Database name"
  value       = module.rds.database_name
}

output "rds_connection_string_ssm_arn" {
  description = "ARN of SSM parameter containing database connection string"
  value       = module.rds.connection_string_ssm_arn
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.rds.security_group_id
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

# ============================================================
# RDS MANAGEMENT COMMANDS
# ============================================================

output "rds_identifier" {
  description = "RDS instance identifier"
  value       = "${local.environment}-postgres"
}

output "rds_stop_command" {
  description = "Command to stop RDS (saves ~$13/month when stopped)"
  value       = <<-EOT
    aws rds stop-db-instance \
      --db-instance-identifier ${local.environment}-postgres \
      --region ${local.region}
  EOT
}

output "rds_start_command" {
  description = "Command to start RDS"
  value       = <<-EOT
    aws rds start-db-instance \
      --db-instance-identifier ${local.environment}-postgres \
      --region ${local.region}
  EOT
}

output "rds_status_command" {
  description = "Command to check RDS status"
  value       = <<-EOT
    aws rds describe-db-instances \
      --db-instance-identifier ${local.environment}-postgres \
      --region ${local.region} \
      --query 'DBInstances[0].DBInstanceStatus' \
      --output text
  EOT
}

output "rds_management_info" {
  description = "RDS management instructions"
  value       = <<-EOT

    RDS Cost Management:
    ====================

    Instance: ${local.environment}-postgres
    Cost when running: ~$13/month + $3/month storage = $16/month
    Cost when stopped: $3/month (storage only)

    Stop RDS (to save costs):
      terraform output -raw rds_stop_command | bash

    Start RDS (when needed):
      terraform output -raw rds_start_command | bash

    Check RDS status:
      terraform output -raw rds_status_command | bash

    Note: RDS automatically starts after 7 days of being stopped.
  EOT
}
