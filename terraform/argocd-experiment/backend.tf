# Terraform Backend Configuration
# Stores state in S3 for remote access and state locking
terraform {
  backend "s3" {
    bucket       = "generic-gha-terraform-state"
    key          = "experiments/argocd-experiment/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
