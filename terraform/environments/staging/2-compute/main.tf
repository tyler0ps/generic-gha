# ============================================================
# COMPUTE LAYER
# ============================================================
# Short-lived resources: ECS, ALB, Services
# Can be destroyed and recreated frequently

# ============================================================
# ECS CLUSTER
# ============================================================

module "ecs_cluster" {
  source = "../../../modules/ecs-cluster"

  name                      = "${local.project}-${local.environment}"
  environment               = local.environment
  enable_container_insights = false # Cost saving
  use_spot                  = true  # Cost saving
}

# ============================================================
# APPLICATION LOAD BALANCER
# ============================================================

module "alb" {
  source = "../../../modules/alb"

  name                       = "${local.project}-${local.environment}"
  environment                = local.environment
  vpc_id                     = local.vpc_id
  public_subnets             = local.public_subnets
  enable_deletion_protection = false # Easy destruction
}

# ============================================================
# GO API SERVICE
# ============================================================

module "api_golang" {
  source = "../../../modules/ecs-service-v2"

  name        = "api-golang"
  environment = local.environment
  region      = local.region

  # Container configuration
  # container_image = "${data.aws_ecr_repository.api_golang.repository_url}:${local.environment}"
  container_image = "${data.aws_ecr_repository.api_golang.repository_url}:1.3.3-0019-g89447fe"
  container_port  = local.services["api-golang"].port
  cpu             = local.services["api-golang"].cpu
  memory          = local.services["api-golang"].memory
  desired_count   = local.services["api-golang"].desired_count

  # Networking
  vpc_id                = local.vpc_id
  private_subnets       = local.private_subnets
  alb_security_group_id = module.alb.security_group_id

  # Database access - add db_access security group
  additional_security_groups = [local.db_access_security_group_id]

  # Load balancer
  listener_arn      = module.alb.http_listener_arn
  health_check_path = local.services["api-golang"].health_check_path
  path_pattern      = local.services["api-golang"].path_pattern
  priority          = local.services["api-golang"].priority

  # ECS cluster
  cluster_id = module.ecs_cluster.cluster_id

  # Database connection via SSM Parameter Store
  secrets = {
    DATABASE_URL = local.rds_connection_string_ssm_arn
  }

  # Port configuration
  environment_variables = {
    PORT = tostring(local.services["api-golang"].port)
  }
}

# ============================================================
# GO API SERVICE
# ============================================================

module "api_node" {
  source = "../../../modules/ecs-service-v2"

  name        = "api-node"
  environment = local.environment
  region      = local.region

  # Container configuration
  container_image = "${data.aws_ecr_repository.api_node.repository_url}:1.1.2-0016-gf1a3460"
  container_port  = local.services["api-node"].port
  cpu             = local.services["api-node"].cpu
  memory          = local.services["api-node"].memory
  desired_count   = local.services["api-node"].desired_count

  # Networking
  vpc_id                = local.vpc_id
  private_subnets       = local.private_subnets
  alb_security_group_id = module.alb.security_group_id

  # Database access - add db_access security group
  additional_security_groups = [local.db_access_security_group_id]

  # Load balancer
  listener_arn      = module.alb.http_listener_arn
  health_check_path = local.services["api-node"].health_check_path
  path_pattern      = local.services["api-node"].path_pattern
  priority          = local.services["api-node"].priority

  # ECS cluster
  cluster_id = module.ecs_cluster.cluster_id

  # Database connection via SSM Parameter Store
  secrets = {
    DATABASE_URL = local.rds_connection_string_ssm_arn
  }

  # Port configuration
  environment_variables = {
    PORT = tostring(local.services["api-node"].port)
  }
}

# ============================================================
# DATABASE MIGRATOR TASK
# ============================================================

# IAM role for task execution (ECS agent needs this)
resource "aws_iam_role" "migrator_execution" {
  name = "${local.environment}-migrator-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "migrator_execution" {
  role       = aws_iam_role.migrator_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow reading DATABASE_URL from SSM
resource "aws_iam_role_policy" "migrator_ssm" {
  role = aws_iam_role.migrator_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameters", "ssm:GetParameter"]
      Resource = [local.rds_connection_string_ssm_arn]
    }]
  })
}

# IAM role for the task itself (empty, but required)
resource "aws_iam_role" "migrator_task" {
  name = "${local.environment}-migrator-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# CloudWatch log group for migrator logs
resource "aws_cloudwatch_log_group" "migrator" {
  name              = "/ecs/${local.environment}/migrator"
  retention_in_days = 7
}

# Task definition for database migrator
resource "aws_ecs_task_definition" "migrator" {
  family                   = "${local.environment}-migrator"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.migrator_execution.arn
  task_role_arn            = aws_iam_role.migrator_task.arn

  # Use ARM64 (Graviton2) - cheaper and matches images built on M1/M2 Macs
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name  = "migrator"
    image = "${data.aws_ecr_repository.api_golang_migrator.repository_url}:${local.environment}"

    # golang-migrate command: migrate -path=/migrations -database=$DATABASE_URL up
    # Use entrypoint override to run through shell for env var substitution
    entrypoint = ["/bin/sh", "-c"]
    command    = ["migrate -path=/app/migrations -database=$DATABASE_URL up"]

    # Get DATABASE_URL from SSM Parameter Store
    secrets = [{
      name      = "DATABASE_URL"
      valueFrom = local.rds_connection_string_ssm_arn
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.migrator.name
        "awslogs-region"        = local.region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    essential = true
  }])
}
