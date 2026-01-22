# VPC module optimized for EKS workloads

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project}-${var.environment}-eks"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  # COST OPTIMIZATION: Single NAT gateway for staging
  # Production can override with one_nat_gateway_per_az = true
  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az

  # Required for EKS
  enable_dns_hostnames = true
  enable_dns_support   = true

  # EKS tags for subnet discovery
  public_subnet_tags = {
    "kubernetes.io/role/elb"                                  = 1
    "kubernetes.io/cluster/${var.project}-${var.environment}" = "shared"
    "karpenter.sh/discovery"                                  = "${var.project}-${var.environment}"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                         = 1
    "kubernetes.io/cluster/${var.project}-${var.environment}" = "shared"
    "karpenter.sh/discovery"                                  = "${var.project}-${var.environment}"
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project}-${var.environment}-eks-vpc"
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}
