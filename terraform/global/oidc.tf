# ============================================================
# GITHUB OIDC SETUP
# ============================================================
# Enables GitHub Actions to authenticate with AWS using OIDC

module "github_oidc" {
  source = "../modules/github-oidc"

  github_org  = "tyler0ps"
  github_repo = "generic-gha"

  # Pass ECR repository ARNs from the ECR module
  ecr_repository_arns = values(module.ecr.repository_arns)

  terraform_state_bucket = "generic-gha-terraform-state"
  region                 = var.region

  allowed_branches = ["main"]

  tags = {
    Project   = var.project
    ManagedBy = "terraform"
    Layer     = "global"
  }
}
