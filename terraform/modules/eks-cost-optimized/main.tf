# EKS Cluster with cost optimization features

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = "${var.project}-${var.environment}"
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnets

  # Cluster endpoint configuration
  # Public endpoint for simplicity and cost (no VPN needed)
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_endpoint_private_access = var.cluster_endpoint_private_access

  # Enable IRSA (IAM Roles for Service Accounts) - required for Karpenter and security
  enable_irsa = true

  # Cluster encryption (optional, can be enabled later)
  cluster_encryption_config = {
    resources        = var.enable_cluster_encryption ? ["secrets"] : []
    provider_key_arn = var.enable_cluster_encryption ? var.kms_key_arn : ""
  }

  # Minimal initial node group for Karpenter and system pods
  eks_managed_node_groups = {
    karpenter = {
      # ARM-based instances for cost savings (20% cheaper than x86)
      instance_types = ["t4g.small"]

      # Use SPOT for cost optimization
      capacity_type = "SPOT"

      # Minimal size - just enough for Karpenter to run
      min_size     = 1
      max_size     = 2
      desired_size = 1

      # Labels and taints to ensure only Karpenter runs here
      labels = {
        role = "karpenter"
      }

      taints = [{
        key    = "karpenter.sh/controller"
        value  = "true"
        effect = "NO_SCHEDULE"
      }]

      # Tags for Karpenter discovery
      tags = merge(
        var.tags,
        {
          "karpenter.sh/discovery" = "${var.project}-${var.environment}"
        }
      )
    }
  }

  # Cluster add-ons (free, essential for cluster operation)
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
      configuration_values = jsonencode({
        env = {
          # Enable prefix delegation for more IP addresses per node
          ENABLE_PREFIX_DELEGATION = "true"
        }
      })
    }
  }

  # Allow access to cluster
  enable_cluster_creator_admin_permissions = true

  # Cluster access configuration
  # authentication_mode = "API_AND_CONFIG_MAP"  # Supports both EKS API and ConfigMap

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-eks"
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}
