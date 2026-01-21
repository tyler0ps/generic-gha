# ============================================================
# REMOTE STATE DATA SOURCES
# ============================================================
# Read outputs from VPC and database layers

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "generic-gha-terraform-state"
    key    = "staging/1-vpc/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

data "terraform_remote_state" "database" {
  backend = "s3"

  config = {
    bucket = "generic-gha-terraform-state"
    key    = "staging/2-database/terraform.tfstate"
    region = "ap-southeast-1"
  }
}
