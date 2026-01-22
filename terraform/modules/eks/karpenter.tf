# # Karpenter - Cost-optimized autoscaling for Kubernetes

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name = module.eks.cluster_name

  # Enable IRSA for Karpenter
  enable_irsa                     = true
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["kube-system:karpenter"]

  # Create separate IAM role for Karpenter-managed nodes
  create_node_iam_role = true

  # SQS queue for Spot interruption handling
  enable_spot_termination = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-karpenter"
      Project     = var.project
      Environment = var.environment
    }
  )
}

# Install Karpenter via Helm
resource "helm_release" "karpenter" {
  namespace        = "kube-system"
  create_namespace = false
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.karpenter_version
  wait             = false

  values = [
    <<-EOT
    settings:
      clusterName: ${module.eks.cluster_name}
      clusterEndpoint: ${module.eks.cluster_endpoint}
      interruptionQueue: ${module.karpenter.queue_name}

    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: ${module.karpenter.iam_role_arn}

    controller:
      resources:
        requests:
          cpu: 500m
          memory: 512Mi
        limits:
          cpu: 1000m
          memory: 1Gi

    webhook:
      enabled: false
    EOT
  ]

  depends_on = [
    module.eks,
    module.karpenter
  ]
}

# Additional IAM permissions required by Karpenter
resource "aws_iam_role_policy" "karpenter_additional_permissions" {
  name = "KarpenterAdditionalPermissions"
  role = split("/", module.karpenter.iam_role_arn)[1]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:ListInstanceProfiles",
          "iam:GetInstanceProfile"
        ]
        Resource = "*"
      }
    ]
  })
}
