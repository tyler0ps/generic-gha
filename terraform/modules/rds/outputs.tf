output "endpoint" {
  description = "RDS endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "address" {
  description = "RDS hostname"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "RDS port"
  value       = aws_db_instance.this.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.this.db_name
}

output "master_username" {
  description = "Master username"
  value       = aws_db_instance.this.username
}

output "password_ssm_arn" {
  description = "ARN of the SSM parameter containing the password"
  value       = aws_ssm_parameter.db_password.arn
}

output "connection_string_ssm_arn" {
  description = "ARN of the SSM parameter containing the connection string"
  value       = aws_ssm_parameter.db_connection_string.arn
}

output "security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}
