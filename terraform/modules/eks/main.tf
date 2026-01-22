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

  # Tags for node security group (used by Karpenter for discovery)
  node_security_group_tags = {
    "karpenter.sh/discovery" = "${var.project}-${var.environment}"
  }

  # Cluster encryption (optional, can be enabled later)
  # cluster_encryption_config = var.enable_cluster_encryption ? {
  #   resources        = ["secrets"]
  #   provider_key_arn = var.kms_key_arn
  # } : {}

  # Minimal initial node group for Karpenter and system pods
  eks_managed_node_groups = {
    karpenter = {
      # x86_64 instances for compatibility with AL2023_x86_64_STANDARD AMI
      instance_types = ["m5.large"]

      # Use SPOT for cost optimization
      capacity_type = "SPOT"

      # Minimal size - just enough for Karpenter to run
      min_size     = 1
      max_size     = 3
      desired_size = 1

      # Labels and taints to ensure only Karpenter runs here
      labels = {
          role = "karpenter"
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }

      # taints = [{
      #   key    = "karpenter.sh/controller"
      #   value  = "true"
      #   effect = "NO_SCHEDULE"
      # }]

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
    eks-pod-identity-agent = {}
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
