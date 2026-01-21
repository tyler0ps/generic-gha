variable "project" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be deployed"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "enable_cluster_encryption" {
  description = "Enable encryption for Kubernetes secrets using KMS"
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "ARN of KMS key for cluster encryption"
  type        = string
  default     = ""
}

variable "karpenter_version" {
  description = "Version of Karpenter to install"
  type        = string
  default     = "1.0.1"
}

variable "enable_fargate_profiles" {
  description = "Enable Fargate profiles for workloads"
  type        = bool
  default     = true
}

variable "fargate_namespace" {
  description = "Namespace for Fargate workloads"
  type        = string
  default     = "staging"
}

variable "enable_argocd_fargate_profile" {
  description = "Enable Fargate profile for ArgoCD (Phase 2)"
  type        = bool
  default     = false
}

variable "enable_external_secrets_fargate_profile" {
  description = "Enable Fargate profile for External Secrets (Phase 2)"
  type        = bool
  default     = false
}

variable "enable_external_secrets_irsa" {
  description = "Enable IRSA for External Secrets Operator (Phase 2)"
  type        = bool
  default     = false
}

variable "enable_alb_controller_irsa" {
  description = "Enable IRSA for AWS Load Balancer Controller"
  type        = bool
  default     = false
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
