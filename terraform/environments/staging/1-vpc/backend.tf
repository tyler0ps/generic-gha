# Backend configuration for VPC layer
terraform {
  backend "s3" {
    bucket       = "generic-gha-terraform-state"
    key          = "staging/1-vpc/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
