resource "aws_db_subnet_group" "this" {
  name       = "${var.environment}-${var.name}"
  subnet_ids = var.private_subnets

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}"
    Environment = var.environment
  })
}

resource "aws_security_group" "rds" {
  name        = "${var.environment}-${var.name}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.allowed_security_groups
    content {
      from_port       = 5432
      to_port         = 5432
      protocol        = "tcp"
      security_groups = [ingress.value]
    }
  }

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}-rds-sg"
    Environment = var.environment
  })
}

resource "random_password" "master" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.environment}/${var.name}/db-password"
  description = "Database master password"
  type        = "SecureString"
  value       = random_password.master.result

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_ssm_parameter" "db_connection_string" {
  name        = "/${var.environment}/${var.name}/db-connection-string"
  description = "Database connection string"
  type        = "SecureString"
  value       = "postgresql://${var.master_username}:${random_password.master.result}@${aws_db_instance.this.endpoint}/${var.database_name}"

  tags = merge(var.tags, {
    Environment = var.environment
  })
}

resource "aws_db_instance" "this" {
  identifier = "${var.environment}-${var.name}"

  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage

  db_name  = var.database_name
  username = var.master_username
  password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible = false
  multi_az            = var.multi_az

  # Easy destruction settings
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.environment}-${var.name}-final"
  backup_retention_period   = var.backup_retention_period
  delete_automated_backups  = true

  # Performance Insights
  performance_insights_enabled = var.performance_insights_enabled

  tags = merge(var.tags, {
    Name        = "${var.environment}-${var.name}"
    Environment = var.environment
  })
}
