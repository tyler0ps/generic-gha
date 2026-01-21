# ============================================================
# REMOTE STATE DATA SOURCES
# ============================================================
# Read outputs from VPC layer

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "generic-gha-terraform-state"
    key    = "staging/1-vpc/terraform.tfstate"
    region = "ap-southeast-1"
  }
}
