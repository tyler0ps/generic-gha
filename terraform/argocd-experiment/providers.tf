# ============================================================
# TERRAFORM AND PROVIDER VERSION CONSTRAINTS
# ============================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "alekc/kubectl"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# ============================================================
# AWS PROVIDER
# ============================================================

provider "aws" {
  region = local.region

  default_tags {
    tags = local.tags
  }
}

# ============================================================
# KUBERNETES PROVIDER
# Configured to use karpenter-experiment cluster via remote state
# ============================================================

provider "kubernetes" {
  host                   = data.terraform_remote_state.karpenter_experiment.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.karpenter_experiment.outputs.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.terraform_remote_state.karpenter_experiment.outputs.cluster_name,
      "--region",
      local.region
    ]
  }
}

# ============================================================
# HELM PROVIDER
# For installing ArgoCD Helm chart
# ============================================================

provider "helm" {
  kubernetes = {
    host                   = data.terraform_remote_state.karpenter_experiment.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.karpenter_experiment.outputs.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name",
        data.terraform_remote_state.karpenter_experiment.outputs.cluster_name,
        "--region",
        local.region
      ]
    }
  }
}

# ============================================================
# KUBECTL PROVIDER
# For applying ArgoCD Application CRDs
# ============================================================

provider "kubectl" {
  host                   = data.terraform_remote_state.karpenter_experiment.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.karpenter_experiment.outputs.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      data.terraform_remote_state.karpenter_experiment.outputs.cluster_name,
      "--region",
      local.region
    ]
  }
}
