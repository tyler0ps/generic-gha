# ============================================================
# LOCAL VARIABLES
# Configuration for ArgoCD experiment
# ============================================================

locals {
  # Experiment configuration
  experiment_name = "argocd-experiment"
  region          = "ap-southeast-1"

  # ArgoCD configuration
  argocd_version   = "9.3.3"
  argocd_namespace = "argocd"

  # GitOps repository configuration
  gitops_repo_url  = "git@github.com:tyler0ps/application-gitops.git"
  gitops_repo_path = "/Users/tyler0ps/workspace/second-layoff-spirit/application-gitops"

  # Resource tags
  tags = {
    Project     = "argocd-experiment"
    Environment = "experiment"
    ManagedBy   = "terraform"
    Purpose     = "learning-argocd-gitops"
  }
}
