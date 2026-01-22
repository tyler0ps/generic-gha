# ============================================================
# EKS LAYER OUTPUTS
# ============================================================
# These outputs are consumed by other layers via remote state

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

# ArgoCD Outputs
output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = module.argocd.namespace
}

output "argocd_admin_password_command" {
  description = "Command to get ArgoCD admin password"
  value       = module.argocd.admin_password_command
}

output "argocd_server_service" {
  description = "ArgoCD server service name"
  value       = module.argocd.server_service
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
