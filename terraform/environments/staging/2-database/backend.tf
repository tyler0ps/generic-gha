# Backend configuration for database layer
terraform {
  backend "s3" {
    bucket       = "generic-gha-terraform-state"
    key          = "staging/2-database/terraform.tfstate"
    region       = "ap-southeast-1"
    use_lockfile = true
    encrypt      = true
  }
}
