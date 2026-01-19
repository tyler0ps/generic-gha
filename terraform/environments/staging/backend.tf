# Uncomment after creating the S3 bucket
terraform {
  backend "s3" {
    bucket       = "generic-gha-terraform-state"
    key          = "staging/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}
