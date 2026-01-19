module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.cidr

  azs             = var.azs
  private_subnets = [for i, az in var.azs : cidrsubnet(var.cidr, 8, i)]
  public_subnets  = [for i, az in var.azs : cidrsubnet(var.cidr, 8, i + 100)]

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Environment = var.environment
  })
}
