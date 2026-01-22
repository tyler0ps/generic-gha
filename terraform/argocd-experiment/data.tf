# ============================================================
# DATA SOURCES
# Read karpenter-experiment cluster information via remote state
# ============================================================

data "terraform_remote_state" "karpenter_experiment" {
  backend = "s3"

  config = {
    bucket = "generic-gha-terraform-state"
    key    = "experiments/karpenter-experiment/terraform.tfstate"
    region = "ap-southeast-1"
  }
}

# Outputs available from karpenter_experiment:
# - cluster_name
# - cluster_endpoint
# - cluster_certificate_authority_data
# - cluster_version
# - region
# - vpc_id
