# ============================================================
# OUTPUTS
# ============================================================

output "service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.service.name
}

output "service_id" {
  description = "ARN of the ECS service"
  value       = aws_ecs_service.service.id
}

output "task_definition_arn" {
  description = "ARN of the task definition"
  value       = aws_ecs_task_definition.service.arn
}

output "security_group_id" {
  description = "Security group ID of the service"
  value       = aws_security_group.service.id
}

output "target_group_arn" {
  description = "ARN of the target group (empty if load balancer is disabled)"
  value       = length(aws_lb_target_group.service) > 0 ? aws_lb_target_group.service[0].arn : ""
}

output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.service.name
}
