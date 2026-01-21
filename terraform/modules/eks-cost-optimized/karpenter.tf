# Karpenter - Cost-optimized autoscaling for Kubernetes

module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name = module.eks.cluster_name

  # Enable IRSA for Karpenter
  enable_irsa                     = true
  irsa_oidc_provider_arn          = module.eks.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  # Use the node IAM role from the Karpenter node group
  create_node_iam_role = false
  node_iam_role_arn    = module.eks.eks_managed_node_groups["karpenter"].iam_role_arn

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
  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  set = [
    {
      name  = "settings.clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "settings.interruptionQueue"
      value = module.karpenter.queue_name
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = module.karpenter.iam_role_arn
    },
    {
      name  = "controller.resources.requests.cpu"
      value = "500m"
    },
    {
      name  = "controller.resources.requests.memory"
      value = "512Mi"
    },
    {
      name  = "controller.resources.limits.cpu"
      value = "1000m"
    },
    {
      name  = "controller.resources.limits.memory"
      value = "1Gi"
    },
    {
      name  = "tolerations[0].key"
      value = "karpenter.sh/controller"
    },
    {
      name  = "tolerations[0].value"
      value = "true"
    },
    {
      name  = "tolerations[0].effect"
      value = "NoSchedule"
    }
  ]

  depends_on = [
    module.eks
  ]
}
