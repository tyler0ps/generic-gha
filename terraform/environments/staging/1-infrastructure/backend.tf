# Backend configuration for infrastructure state
# This keeps VPC and RDS state separate from compute resources
terraform {
  backend "s3" {
    bucket = "generic-gha-terraform-state"
    key    = "staging/infrastructure/terraform.tfstate"
    region = "ap-southeast-1"
    # Uncomment these for production:
    # encrypt        = true
    # dynamodb_table = "generic-gha-terraform-locks"
  }
}
