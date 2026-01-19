# Backend configuration for compute state
# This keeps ECS, ALB, and services state separate from infrastructure
terraform {
  backend "s3" {
    bucket = "generic-gha-terraform-state"
    key    = "staging/compute/terraform.tfstate"
    region = "ap-southeast-1"
    # Uncomment these for production:
    # encrypt        = true
    # dynamodb_table = "generic-gha-terraform-locks"
  }
}
