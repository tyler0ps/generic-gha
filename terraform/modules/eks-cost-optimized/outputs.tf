output "cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_version" {
  description = "The Kubernetes server version for the cluster"
  value       = module.eks.cluster_version
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC Provider for EKS"
  value       = module.eks.oidc_provider_arn
}

output "node_security_group_id" {
  description = "Security group ID attached to the EKS nodes"
  value       = module.eks.node_security_group_id
}

# Karpenter outputs
output "karpenter_irsa_arn" {
  description = "ARN of IAM role for Karpenter"
  value       = module.karpenter.iam_role_arn
}

output "karpenter_instance_profile_name" {
  description = "Name of instance profile for Karpenter"
  value       = module.karpenter.instance_profile_name
}

output "karpenter_queue_name" {
  description = "Name of SQS queue for Karpenter spot termination handling"
  value       = module.karpenter.queue_name
}

# IRSA outputs (Phase 2)
output "external_secrets_irsa_arn" {
  description = "ARN of IAM role for External Secrets Operator"
  value       = var.enable_external_secrets_irsa ? module.external_secrets_irsa[0].iam_role_arn : null
}

output "alb_controller_irsa_arn" {
  description = "ARN of IAM role for AWS Load Balancer Controller"
  value       = var.enable_alb_controller_irsa ? module.aws_load_balancer_controller_irsa[0].iam_role_arn : null
}

# Fargate outputs
output "fargate_pod_execution_role_arn" {
  description = "ARN of Fargate pod execution role"
  value       = aws_iam_role.fargate_pod_execution.arn
}
