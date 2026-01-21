# ============================================================
# EKS INFRASTRUCTURE
# ============================================================
# New dedicated VPC and EKS cluster for the migration from ECS

# ============================================================
# EKS VPC (Dedicated)
# ============================================================

module "vpc_eks" {
  source = "../../../modules/vpc-eks"

  project     = local.project
  environment = local.environment

  # New VPC CIDR (separate from existing ECS VPC 10.0.0.0/16)
  vpc_cidr = "10.1.0.0/16"

  availability_zones   = local.azs
  private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
  public_subnet_cidrs  = ["10.1.101.0/24", "10.1.102.0/24"]

  # COST OPTIMIZATION: Single NAT gateway for staging
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "Terraform"
    Purpose     = "EKS"
  }
}

# ============================================================
# VPC PEERING (EKS <-> ECS)
# ============================================================
# Allow EKS pods to access RDS in the existing ECS VPC

resource "aws_vpc_peering_connection" "eks_to_ecs" {
  vpc_id      = module.vpc_eks.vpc_id
  peer_vpc_id = module.vpc.vpc_id
  auto_accept = true

  tags = {
    Name        = "${local.project}-${local.environment}-eks-to-ecs"
    Environment = local.environment
    Purpose     = "EKS to ECS VPC peering for RDS access"
  }
}

# Route from EKS VPC to ECS VPC (for RDS access)
resource "aws_route" "eks_to_ecs" {
  count = length(module.vpc_eks.private_route_table_ids)

  route_table_id            = module.vpc_eks.private_route_table_ids[count.index]
  destination_cidr_block    = module.vpc.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.eks_to_ecs.id
}

# Route from ECS VPC to EKS VPC (optional, for reverse communication)
resource "aws_route" "ecs_to_eks" {
  count = length(module.vpc.private_route_table_ids)

  route_table_id            = module.vpc.private_route_table_ids[count.index]
  destination_cidr_block    = module.vpc_eks.vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.eks_to_ecs.id
}

# ============================================================
# EKS CLUSTER
# ============================================================

module "eks" {
  source = "../../../modules/eks-cost-optimized"

  project     = local.project
  environment = local.environment

  cluster_version = "1.34"

  vpc_id          = module.vpc_eks.vpc_id
  private_subnets = module.vpc_eks.private_subnets

  # Public endpoint for easy access (no VPN needed)
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # Fargate profiles for cost-optimized workloads
  enable_fargate_profiles = true
  fargate_namespace       = local.environment

  # Phase 2 features (disabled for now)
  enable_argocd_fargate_profile           = false
  enable_external_secrets_fargate_profile = false
  enable_external_secrets_irsa            = false
  enable_alb_controller_irsa              = false

  # AWS account information for IRSA
  aws_region     = local.region
  aws_account_id = data.aws_caller_identity.current.account_id

  tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "Terraform"
  }

  depends_on = [module.vpc_eks]
}

# ============================================================
# SECURITY GROUP RULES FOR RDS ACCESS FROM EKS
# ============================================================

# Allow EKS pods to access RDS
resource "aws_security_group_rule" "rds_from_eks" {
  type              = "ingress"
  description       = "Allow RDS access from EKS pods"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = module.vpc_eks.private_subnet_cidrs
  security_group_id = aws_security_group.db_access.id
}

# Allow EKS node-to-node communication
resource "aws_security_group" "eks_additional" {
  name        = "${local.project}-${local.environment}-eks-additional"
  description = "Additional security group for EKS pods"
  vpc_id      = module.vpc_eks.vpc_id

  ingress {
    description = "Allow pod-to-pod communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.project}-${local.environment}-eks-additional"
    Environment = local.environment
  }
}
