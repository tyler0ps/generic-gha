# Uncomment after creating the S3 bucket
terraform {
  backend "s3" {
    bucket       = "generic-gha-terraform-state"
    key          = "global/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}

# To bootstrap state backend, run these commands first:
# aws s3api create-bucket --bucket generic-gha-terraform-state --region ap-southeast-1 --create-bucket-configuration LocationConstraint=ap-southeast-1
# aws s3api put-bucket-versioning --bucket generic-gha-terraform-state --versioning-configuration Status=Enabled
