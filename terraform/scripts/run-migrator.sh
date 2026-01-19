#!/bin/bash
set -e

ENVIRONMENT="${1:-staging}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="${SCRIPT_DIR}/../environments/${ENVIRONMENT}"

if [ ! -d "$ENV_DIR" ]; then
    echo "Error: Environment directory not found: $ENV_DIR"
    echo "Usage: $0 [staging|production]"
    exit 1
fi

cd "$ENV_DIR"

echo "=========================================="
echo "  Running Database Migrator"
echo "  Environment: ${ENVIRONMENT}"
echo "=========================================="
echo ""

# Get outputs from Terraform
CLUSTER_ARN=$(terraform output -raw ecs_cluster_arn 2>/dev/null)
TASK_DEF=$(terraform output -raw migrator_task_definition 2>/dev/null)
SUBNETS=$(terraform output -json private_subnets 2>/dev/null | jq -r 'join(",")')
SECURITY_GROUPS=$(terraform output -json migrator_security_group_ids 2>/dev/null | jq -r 'join(",")')

if [ -z "$CLUSTER_ARN" ] || [ -z "$TASK_DEF" ]; then
    echo "Error: Could not get required outputs from Terraform."
    echo "Make sure you have applied the Terraform configuration first."
    exit 1
fi

echo "Cluster: $CLUSTER_ARN"
echo "Task Definition: $TASK_DEF"
echo "Subnets: $SUBNETS"
echo "Security Groups: $SECURITY_GROUPS"
echo ""

echo "Starting migration task..."

TASK_ARN=$(aws ecs run-task \
    --cluster "$CLUSTER_ARN" \
    --task-definition "$TASK_DEF" \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUPS],assignPublicIp=DISABLED}" \
    --query 'tasks[0].taskArn' \
    --output text)

echo "Task started: $TASK_ARN"
echo ""
echo "Waiting for task to complete..."

aws ecs wait tasks-stopped --cluster "$CLUSTER_ARN" --tasks "$TASK_ARN"

# Get task exit code
EXIT_CODE=$(aws ecs describe-tasks \
    --cluster "$CLUSTER_ARN" \
    --tasks "$TASK_ARN" \
    --query 'tasks[0].containers[0].exitCode' \
    --output text)

echo ""
if [ "$EXIT_CODE" = "0" ]; then
    echo "=========================================="
    echo "  Migration completed successfully!"
    echo "=========================================="
else
    echo "=========================================="
    echo "  Migration failed with exit code: $EXIT_CODE"
    echo "=========================================="
    echo ""
    echo "Check CloudWatch logs for details:"
    echo "  Log group: /ecs/${ENVIRONMENT}/api-golang-migrator"
    exit 1
fi
