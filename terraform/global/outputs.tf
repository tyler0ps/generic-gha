output "ecr_repository_urls" {
  description = "Map of ECR repository URLs"
  value       = module.ecr.repository_urls
}

output "ecr_repository_arns" {
  description = "Map of ECR repository ARNs"
  value       = module.ecr.repository_arns
}

# ============================================================
# GITHUB OIDC OUTPUTS
# ============================================================

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = module.github_oidc.oidc_provider_arn
}

output "github_actions_ecr_role_arn" {
  description = "ARN of IAM role for GitHub Actions ECR operations"
  value       = module.github_oidc.ecr_role_arn
}

output "github_actions_terraform_role_arn" {
  description = "ARN of IAM role for GitHub Actions Terraform operations"
  value       = module.github_oidc.terraform_role_arn
}
