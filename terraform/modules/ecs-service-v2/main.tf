# ============================================================
# SIMPLIFIED ECS SERVICE FOR REACT CLIENT
# ============================================================
# This module deploys a React app to ECS Fargate with ALB
# Only the essential components are included for clarity

# ============================================================
# 1. IAM ROLE - Task Execution (ECS Agent needs this)
# ============================================================
# This role allows ECS to:
# - Pull container images from ECR
# - Write logs to CloudWatch

resource "aws_iam_role" "task_execution" {
  name = "${var.environment}-${var.name}-exec"

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

# Attach AWS managed policy for ECR and CloudWatch access
resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Allow reading secrets from SSM Parameter Store
resource "aws_iam_role_policy" "task_execution_ssm" {
  count = length(var.secrets) > 0 ? 1 : 0
  role  = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue"
      ]
      Resource = values(var.secrets)
    }]
  })
}

# ============================================================
# 2. IAM ROLE - Task (Your app uses this at runtime)
# ============================================================
# React app doesn't need AWS permissions, so this is empty
# But ECS requires a task role to exist

resource "aws_iam_role" "task" {
  name = "${var.environment}-${var.name}-task"

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

# ============================================================
# 3. CLOUDWATCH LOG GROUP
# ============================================================
# Stores container logs

resource "aws_cloudwatch_log_group" "service" {
  name              = "/ecs/${var.environment}/${var.name}"
  retention_in_days = 7 # Keep logs for 7 days
}

# ============================================================
# 4. SECURITY GROUP
# ============================================================
# Controls network traffic to/from the container

resource "aws_security_group" "service" {
  name        = "${var.environment}-${var.name}-sg"
  description = "Security group for ${var.name}"
  vpc_id      = var.vpc_id

  # Allow inbound traffic from ALB only
  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Allow all outbound traffic (for pulling images, database access, etc)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.name}-sg"
    Environment = var.environment
  }
}

# ============================================================
# 5. TASK DEFINITION
# ============================================================
# Defines what container to run and its configuration

resource "aws_ecs_task_definition" "service" {
  family                   = "${var.environment}-${var.name}"
  network_mode             = "awsvpc" # Required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  # Use ARM64 (Graviton2) - cheaper and matches images built on M1/M2 Macs
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([{
    name  = var.name
    image = var.container_image

    portMappings = [{
      containerPort = var.container_port
      protocol      = "tcp"
    }]

    # Environment variables
    environment = [
      for key, value in var.environment_variables : {
        name  = key
        value = value
      }
    ]

    # Secrets from SSM Parameter Store
    secrets = [
      for key, arn in var.secrets : {
        name      = key
        valueFrom = arn
      }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.service.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "ecs"
      }
    }

    essential = true
  }])
}

# ============================================================
# 6. TARGET GROUP
# ============================================================
# ALB uses this to route traffic to container instances

resource "aws_lb_target_group" "service" {
  name        = "${var.environment}-${var.name}"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  deregistration_delay = 30 # Reduce from 300s default to 30s

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-299"
  }
}

# ============================================================
# 7. LISTENER RULE
# ============================================================
# Routes requests matching path_pattern to this service

resource "aws_lb_listener_rule" "service" {
  listener_arn = var.listener_arn
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.service.arn
  }

  condition {
    path_pattern {
      values = var.path_pattern
    }
  }
}

# ============================================================
# 8. ECS SERVICE
# ============================================================
# Actually runs and maintains the desired number of tasks

resource "aws_ecs_service" "service" {
  name            = var.name
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = var.desired_count

  # Use Fargate Spot for cost savings
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 100
  }

  # Network configuration
  network_configuration {
    subnets = var.private_subnets
    security_groups = concat(
      [aws_security_group.service.id],
      var.additional_security_groups
    )
    assign_public_ip = false
  }

  # Connect to load balancer
  load_balancer {
    target_group_arn = aws_lb_target_group.service.arn
    container_name   = var.name
    container_port   = var.container_port
  }

  # Service Discovery registration
  dynamic "service_registries" {
    for_each = var.enable_service_discovery ? [1] : []
    content {
      registry_arn = aws_service_discovery_service.service[0].arn
    }
  }

  # Wait for listener rule to be created
  depends_on = [aws_lb_listener_rule.service]
}

# ============================================================
# 9. SERVICE DISCOVERY (Optional)
# ============================================================
# Registers service with AWS Cloud Map for DNS-based discovery

resource "aws_service_discovery_service" "service" {
  count = var.enable_service_discovery ? 1 : 0

  name = var.name

  dns_config {
    namespace_id = var.service_discovery_namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = {
    Name        = "${var.environment}-${var.name}-discovery"
    Environment = var.environment
  }
}
