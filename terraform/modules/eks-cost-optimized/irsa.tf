# IRSA (IAM Roles for Service Accounts) configurations
# These will be used in Phase 2 for security hardening

# External Secrets Operator IRSA
module "external_secrets_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  count = var.enable_external_secrets_irsa ? 1 : 0

  role_name = "${var.project}-${var.environment}-external-secrets"

  role_policy_arns = {
    policy = aws_iam_policy.external_secrets[0].arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-external-secrets-irsa"
      Project     = var.project
      Environment = var.environment
    }
  )
}

resource "aws_iam_policy" "external_secrets" {
  count = var.enable_external_secrets_irsa ? 1 : 0

  name        = "${var.project}-${var.environment}-external-secrets"
  description = "Policy for External Secrets Operator to access SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/${var.environment}/*",
          "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.environment}/*"
        ]
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-external-secrets-policy"
      Project     = var.project
      Environment = var.environment
    }
  )
}

# AWS Load Balancer Controller IRSA
module "aws_load_balancer_controller_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  count = var.enable_alb_controller_irsa ? 1 : 0

  role_name = "${var.project}-${var.environment}-aws-lb-controller"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-alb-controller-irsa"
      Project     = var.project
      Environment = var.environment
    }
  )
}
