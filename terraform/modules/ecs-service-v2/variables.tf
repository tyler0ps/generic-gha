# ============================================================
# BASIC IDENTIFIERS
# ============================================================

variable "name" {
  description = "Service name (e.g., 'client-react')"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., 'staging')"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

# ============================================================
# CONTAINER CONFIGURATION
# ============================================================

variable "container_image" {
  description = "Docker image URL from ECR (e.g., '123456789.dkr.ecr.region.amazonaws.com/app:tag')"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
}

variable "cpu" {
  description = "CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory in MB"
  type        = number

  default = 512
}

variable "desired_count" {
  description = "Number of container instances to run"
  type        = number
  default     = 1
}

# ============================================================
# NETWORKING
# ============================================================

variable "vpc_id" {
  description = "VPC ID where service will run"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs for running containers"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID of the ALB"
  type        = string
}

# ============================================================
# LOAD BALANCER CONFIGURATION
# ============================================================

variable "listener_arn" {
  description = "ARN of the ALB listener"
  type        = string
}

variable "health_check_path" {
  description = "Path for health check (e.g., '/' or '/health')"
  type        = string
  default     = "/"
}

variable "path_pattern" {
  description = "URL path patterns to route to this service (e.g., ['/*'])"
  type        = list(string)
}

variable "priority" {
  description = "Listener rule priority (lower = higher priority, use 999 for catch-all)"
  type        = number
}

# ============================================================
# ECS CLUSTER
# ============================================================

variable "cluster_id" {
  description = "ECS cluster ID where service will be deployed"
  type        = string
}

# ============================================================
# ENVIRONMENT & SECRETS
# ============================================================

variable "environment_variables" {
  description = "Environment variables to pass to the container"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets from SSM Parameter Store (map of name -> SSM ARN)"
  type        = map(string)
  default     = {}
}

# ============================================================
# ADDITIONAL SECURITY GROUPS
# ============================================================

variable "additional_security_groups" {
  description = "Additional security group IDs to attach (e.g., for database access)"
  type        = list(string)
  default     = []
}

# ============================================================
# SERVICE DISCOVERY
# ============================================================

variable "enable_service_discovery" {
  description = "Enable AWS Cloud Map service discovery"
  type        = bool
  default     = false
}

variable "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  type        = string
  default     = null
}
