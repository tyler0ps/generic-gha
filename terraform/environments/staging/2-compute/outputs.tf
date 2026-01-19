# ============================================================
# COMPUTE OUTPUTS
# ============================================================

# ALB Outputs
output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "alb_url" {
  description = "Full URL of the application"
  value       = "http://${module.alb.alb_dns_name}"
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs_cluster.cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs_cluster.cluster_arn
}

# Migrator Outputs
output "migrator_task_definition" {
  description = "Migrator task definition ARN"
  value       = aws_ecs_task_definition.migrator.arn
}

output "migrator_run_command" {
  description = "AWS CLI command to run the migrator"
  value       = <<-EOT
    aws ecs run-task \
      --cluster ${module.ecs_cluster.cluster_arn} \
      --task-definition ${aws_ecs_task_definition.migrator.arn} \
      --launch-type FARGATE \
      --network-configuration "awsvpcConfiguration={subnets=[${join(",", local.private_subnets)}],securityGroups=[${local.db_access_security_group_id}],assignPublicIp=DISABLED}"
  EOT
}

# Service URLs
output "api_golang_url" {
  description = "Go API URL (via ALB)"
  value       = "http://${module.alb.alb_dns_name}/api/golang/"
}
