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
  default     = "1.8.5"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
