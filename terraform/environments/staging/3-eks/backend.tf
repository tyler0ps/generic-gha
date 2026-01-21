# Backend configuration for EKS layer
terraform {
  backend "s3" {
    bucket       = "generic-gha-terraform-state"
    key          = "staging/3-eks/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
