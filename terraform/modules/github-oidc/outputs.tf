output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "ecr_role_arn" {
  description = "ARN of the IAM role for ECR operations"
  value       = aws_iam_role.github_actions_ecr.arn
}

output "ecr_role_name" {
  description = "Name of the IAM role for ECR operations"
  value       = aws_iam_role.github_actions_ecr.name
}

output "terraform_role_arn" {
  description = "ARN of the IAM role for Terraform operations"
  value       = aws_iam_role.github_actions_terraform.arn
}

output "terraform_role_name" {
  description = "Name of the IAM role for Terraform operations"
  value       = aws_iam_role.github_actions_terraform.name
}
