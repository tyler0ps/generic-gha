# ECS Service Module V2 - Simplified

A simplified ECS Fargate service module that shows the **minimum required components** to deploy a containerized application with an Application Load Balancer.

## Purpose

This module was created to demonstrate the essential AWS resources needed for ECS deployment, without the complexity of the full-featured `ecs-service` module. Perfect for learning and simple use cases like deploying a React frontend.

## What This Module Creates

### 8 Essential Components

```
1. Task Execution Role (IAM)
   └─ Allows ECS to pull images from ECR and write logs

2. Task Role (IAM)
   └─ Allows your app to access AWS services (empty for React)

3. CloudWatch Log Group
   └─ Stores container logs

4. Security Group
   └─ Controls network traffic to/from containers

5. Task Definition
   └─ Defines what container to run (image, CPU, memory, etc.)

6. Target Group
   └─ ALB uses this to route traffic to container instances

7. Listener Rule
   └─ Routes HTTP requests matching a path pattern to your service

8. ECS Service
   └─ Actually runs and maintains your containers
```

## Architecture Flow

```
Internet
   ↓
Application Load Balancer
   ↓
Listener Rule (matches path pattern)
   ↓
Target Group (health checks)
   ↓
ECS Service (maintains desired count)
   ↓
Task Definition (container config)
   ↓
Container (your app running in Fargate)
```

## Minimal Example

```hcl
# Get ECR repository
data "aws_ecr_repository" "app" {
  name = "my-org/my-app"
}

# Deploy the service
module "my_app" {
  source = "../../modules/ecs-service-v2"

  # Basic info
  name        = "my-app"
  environment = "staging"
  region      = "ap-southeast-1"

  # Container
  container_image = "${data.aws_ecr_repository.app.repository_url}:staging"
  container_port  = 8080
  cpu             = 256  # 0.25 vCPU
  memory          = 512  # 512 MB
  desired_count   = 1

  # Networking
  vpc_id                = module.vpc.vpc_id
  private_subnets       = module.vpc.private_subnets
  alb_security_group_id = module.alb.security_group_id

  # Load balancer
  listener_arn      = module.alb.http_listener_arn
  health_check_path = "/"
  path_pattern      = ["/*"]
  priority          = 999  # Catch-all

  # ECS
  cluster_id = module.ecs_cluster.cluster_id
}
```

## Understanding the IAM Roles

### Task Execution Role
**Who uses it?** The ECS agent (AWS infrastructure)

**What for?**
- Pull container images from ECR
- Write logs to CloudWatch
- Read secrets from SSM Parameter Store (if configured)

**Policy attached:**
- `AmazonECSTaskExecutionRolePolicy` (AWS managed)

### Task Role
**Who uses it?** Your application code running inside the container

**What for?**
- Access AWS services (S3, DynamoDB, SQS, etc.)
- For a static React app: **Nothing** (no AWS SDK calls)
- For a backend API: Would need policies for database access, file storage, etc.

**Policy attached:**
- None (in this simplified version)
- Add policies here if your app needs AWS access

## CPU and Memory Combinations

Fargate only allows specific CPU/memory combinations:

| CPU (vCPU) | Memory (MB) Options |
|------------|---------------------|
| 256 (0.25) | 512, 1024, 2048 |
| 512 (0.5)  | 1024 - 4096 (in 1GB increments) |
| 1024 (1)   | 2048 - 8192 (in 1GB increments) |
| 2048 (2)   | 4096 - 16384 (in 1GB increments) |
| 4096 (4)   | 8192 - 30720 (in 1GB increments) |

For a React app, `256/512` is usually sufficient.

## Priority and Path Patterns

The `priority` and `path_pattern` control how the ALB routes traffic:

```hcl
# Example 1: API service
priority     = 100  # Higher priority (lower number)
path_pattern = ["/api/*"]

# Example 2: Admin panel
priority     = 200
path_pattern = ["/admin/*"]

# Example 3: React frontend (catch-all)
priority     = 999  # Lowest priority (highest number)
path_pattern = ["/*"]  # Matches everything
```

**Rule:** Lower priority number = evaluated first

## What's NOT Included (vs full module)

This simplified module does NOT include:

- ❌ Auto-scaling
- ❌ Service discovery
- ❌ Database integration
- ❌ SSM secrets management
- ❌ Environment variable configuration
- ❌ Custom task role policies
- ❌ Additional security groups
- ❌ Lifecycle ignore_changes

These features exist in the full `ecs-service` module but are omitted here for clarity.

## Outputs

```hcl
module.my_app.service_name          # ECS service name
module.my_app.service_id            # ECS service ARN
module.my_app.task_definition_arn   # Task definition ARN
module.my_app.security_group_id     # Security group ID
module.my_app.target_group_arn      # Target group ARN
module.my_app.log_group_name        # CloudWatch log group
```

## Viewing Logs

```bash
# View logs in CloudWatch
aws logs tail /ecs/staging/client-react --follow --region ap-southeast-1
```

## Common Issues

### Container fails health checks
- Check if container is listening on the correct port
- Verify `health_check_path` returns HTTP 200-299
- Check container logs for startup errors

### Can't pull image from ECR
- Ensure task execution role has ECR permissions
- Verify image tag exists in ECR
- Check if ECR repository name is correct

### Service won't start
- Check CPU/memory combination is valid
- Ensure private subnets have NAT gateway (for pulling images)
- Verify security group allows outbound traffic

## Cost Optimization

This module uses:
- **Fargate Spot** (60-70% cheaper than regular Fargate)
- **7-day log retention** (vs default unlimited)
- **No auto-scaling** (keeps costs predictable)

For staging/testing environments only. Production should use regular Fargate with auto-scaling.

## Next Steps

Once you understand this module, check out the full `ecs-service` module which includes:
- Environment variables and secrets management
- Service discovery for microservices
- Database integration
- Auto-scaling based on metrics
