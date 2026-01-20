variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "ecr_repository_arns" {
  description = "List of ECR repository ARNs for push/pull access"
  type        = list(string)
  default     = []
}

variable "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "allowed_branches" {
  description = "Allowed branches for OIDC authentication"
  type        = list(string)
  default     = ["main"]
}

variable "tags" {
  description = "Common tags for resources"
  type        = map(string)
  default     = {}
}
