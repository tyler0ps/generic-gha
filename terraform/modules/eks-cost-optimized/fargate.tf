# Fargate Profiles for cost-optimized workloads

# Fargate execution role
resource "aws_iam_role" "fargate_pod_execution" {
  name = "${var.project}-${var.environment}-fargate-pod-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks-fargate-pods.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-fargate-execution"
      Project     = var.project
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "fargate_pod_execution" {
  role       = aws_iam_role.fargate_pod_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
}

# Fargate profile for application workloads
resource "aws_eks_fargate_profile" "apps" {
  count = var.enable_fargate_profiles ? 1 : 0

  cluster_name           = module.eks.cluster_name
  fargate_profile_name   = "apps"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution.arn

  subnet_ids = var.private_subnets

  selector {
    namespace = var.fargate_namespace
    labels = {
      compute-type = "fargate"
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-fargate-apps"
      Project     = var.project
      Environment = var.environment
    }
  )
}

# Fargate profile for batch jobs (e.g., database migrator)
resource "aws_eks_fargate_profile" "jobs" {
  count = var.enable_fargate_profiles ? 1 : 0

  cluster_name           = module.eks.cluster_name
  fargate_profile_name   = "jobs"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution.arn

  subnet_ids = var.private_subnets

  selector {
    namespace = var.fargate_namespace
    labels = {
      compute-type = "fargate-job"
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-fargate-jobs"
      Project     = var.project
      Environment = var.environment
    }
  )
}

# Fargate profile for ArgoCD (Phase 2)
resource "aws_eks_fargate_profile" "argocd" {
  count = var.enable_argocd_fargate_profile ? 1 : 0

  cluster_name           = module.eks.cluster_name
  fargate_profile_name   = "argocd"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution.arn

  subnet_ids = var.private_subnets

  selector {
    namespace = "argocd"
    labels = {
      compute-type = "fargate"
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-fargate-argocd"
      Project     = var.project
      Environment = var.environment
    }
  )
}

# Fargate profile for External Secrets (Phase 2)
resource "aws_eks_fargate_profile" "external_secrets" {
  count = var.enable_external_secrets_fargate_profile ? 1 : 0

  cluster_name           = module.eks.cluster_name
  fargate_profile_name   = "external-secrets"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution.arn

  subnet_ids = var.private_subnets

  selector {
    namespace = "external-secrets"
    labels = {
      compute-type = "fargate"
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-fargate-external-secrets"
      Project     = var.project
      Environment = var.environment
    }
  )
}
