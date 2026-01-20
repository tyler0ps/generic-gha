# ============================================================
# GITHUB OIDC PROVIDER
# ============================================================
# Allows GitHub Actions to authenticate with AWS without static credentials

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = merge(var.tags, {
    Name = "github-actions-oidc"
  })
}

# ============================================================
# IAM ROLE - ECR (Build & Push Workflow)
# ============================================================

# Trust policy: Only allow specific repo, branches, and tags
resource "aws_iam_role" "github_actions_ecr" {
  name        = "github-actions-ecr-role"
  description = "Role for GitHub Actions to push/pull ECR images"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Allow main branch and all tags
            "token.actions.githubusercontent.com:sub" = concat(
              [for branch in var.allowed_branches : "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"],
              ["repo:${var.github_org}/${var.github_repo}:ref:refs/tags/*"]
            )
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name    = "github-actions-ecr-role"
    Purpose = "ECR push/pull for CI/CD"
  })
}

# Custom policy for ECR operations (least privilege)
resource "aws_iam_role_policy" "github_actions_ecr" {
  name = "ecr-push-pull-policy"
  role = aws_iam_role.github_actions_ecr.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Required for docker login
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        # Required for pushing/pulling images
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = var.ecr_repository_arns
      },
      {
        # Minimal S3 read for Terraform state (if needed)
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}",
          "arn:aws:s3:::${var.terraform_state_bucket}/*"
        ]
      }
    ]
  })
}

# ============================================================
# IAM ROLE - TERRAFORM (Destroy Infrastructure Workflow)
# ============================================================

resource "aws_iam_role" "github_actions_terraform" {
  name        = "github-actions-terraform-role"
  description = "Role for GitHub Actions to run Terraform operations"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Restrict to specific repository and branches
            # Terraform should only run from main branch
            "token.actions.githubusercontent.com:sub" = [
              for branch in var.allowed_branches :
              "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${branch}"
            ]
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name    = "github-actions-terraform-role"
    Purpose = "Terraform infrastructure management"
  })
}

# Custom policy for Terraform operations (comprehensive permissions)
resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "terraform-infrastructure-policy"
  role = aws_iam_role.github_actions_terraform.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # EC2 and VPC operations
        Effect = "Allow"
        Action = [
          "ec2:*",
          "elasticloadbalancing:*"
        ]
        Resource = "*"
      },
      {
        # ECS operations
        Effect = "Allow"
        Action = [
          "ecs:*",
          "logs:*",
          "application-autoscaling:*"
        ]
        Resource = "*"
      },
      {
        # RDS operations
        Effect = "Allow"
        Action = [
          "rds:*"
        ]
        Resource = "*"
      },
      {
        # IAM operations (for creating service roles)
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:TagRole",
          "iam:UntagRole"
        ]
        Resource = [
          "arn:aws:iam::*:role/staging-*",
          "arn:aws:iam::*:role/production-*"
        ]
      },
      {
        # S3 operations (Terraform state)
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}",
          "arn:aws:s3:::${var.terraform_state_bucket}/*"
        ]
      },
      {
        # SSM Parameter Store (for RDS credentials)
        Effect = "Allow"
        Action = [
          "ssm:*"
        ]
        Resource = "*"
      },
      {
        # Service Discovery
        Effect = "Allow"
        Action = [
          "servicediscovery:*"
        ]
        Resource = "*"
      },
      {
        # ECR read access (for Terraform to query repos)
        Effect = "Allow"
        Action = [
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Resource = "*"
      },
      {
        # CloudWatch operations
        Effect = "Allow"
        Action = [
          "cloudwatch:*"
        ]
        Resource = "*"
      }
    ]
  })
}
