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

output "ecs_services_security_group_id" {
  description = "Shared security group ID for inter-service communication"
  value       = aws_security_group.ecs_services.id
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

# Service Discovery Outputs
output "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.id
}

output "service_discovery_namespace_name" {
  description = "Name of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.name
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

# ============================================================
# EKS OUTPUTS
# ============================================================

# EKS VPC Outputs
output "eks_vpc_id" {
  description = "EKS VPC ID"
  value       = module.vpc_eks.vpc_id
}

output "eks_vpc_cidr" {
  description = "EKS VPC CIDR block"
  value       = module.vpc_eks.vpc_cidr_block
}

output "eks_private_subnets" {
  description = "EKS private subnet IDs"
  value       = module.vpc_eks.private_subnets
}

output "eks_public_subnets" {
  description = "EKS public subnet IDs"
  value       = module.vpc_eks.public_subnets
}

# EKS Cluster Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id" {
  description = "EKS node security group ID"
  value       = module.eks.node_security_group_id
}

output "eks_oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS (for IRSA)"
  value       = module.eks.oidc_provider_arn
}

# Karpenter Outputs
output "karpenter_irsa_arn" {
  description = "ARN of IAM role for Karpenter"
  value       = module.eks.karpenter_irsa_arn
}

output "karpenter_instance_profile_name" {
  description = "Name of instance profile for Karpenter"
  value       = module.eks.karpenter_instance_profile_name
}

output "karpenter_queue_name" {
  description = "Name of SQS queue for Karpenter spot termination handling"
  value       = module.eks.karpenter_queue_name
}

# EKS Management Commands
output "eks_kubeconfig_command" {
  description = "Command to configure kubectl for EKS"
  value       = <<-EOT
    aws eks update-kubeconfig \
      --name ${module.eks.cluster_name} \
      --region ${local.region}
  EOT
}

output "eks_management_info" {
  description = "EKS management instructions"
  value       = <<-EOT

    EKS Cluster Information:
    ========================

    Cluster Name: ${module.eks.cluster_name}
    Cluster Endpoint: ${module.eks.cluster_endpoint}
    VPC: ${module.vpc_eks.vpc_id} (10.1.0.0/16)

    Configure kubectl:
      terraform output -raw eks_kubeconfig_command | bash

    Verify cluster access:
      kubectl cluster-info
      kubectl get nodes

    View Karpenter logs:
      kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter -f

    Cost Estimate:
      - EKS Control Plane: $73/month
      - Karpenter node (1x t4g.small Spot): ~$4/month
      - Fargate (per pod, when running): ~$0.01332/hour for 0.25vCPU + 0.5GB
      - With scheduled scaling (70% downtime): ~$104-130/month total

    Next Steps:
      1. Configure kubectl (see command above)
      2. Deploy Karpenter provisioner
      3. Deploy application manifests
      4. Verify services are running
  EOT
}
