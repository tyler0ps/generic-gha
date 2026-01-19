#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PRODUCTION_DIR="${SCRIPT_DIR}/../environments/production"

echo "=========================================="
echo "  ⚠️  PRODUCTION ENVIRONMENT DESTRUCTION  ⚠️"
echo "=========================================="
echo ""
echo "WARNING: This will destroy ALL production infrastructure including:"
echo "  - ECS Cluster and all services"
echo "  - RDS PostgreSQL database (ALL DATA WILL BE LOST)"
echo "  - VPC and networking components"
echo "  - ALB and target groups"
echo "  - CloudWatch log groups"
echo ""
echo "This action is IRREVERSIBLE!"
echo ""
echo "Type 'destroy-production' to confirm:"
read -r confirmation

if [ "$confirmation" != "destroy-production" ]; then
    echo "Aborted. Confirmation did not match."
    exit 1
fi

cd "$PRODUCTION_DIR"

echo ""
echo "Disabling deletion protection on ALB..."
# Note: You may need to manually disable deletion protection first
# terraform apply -target=module.alb -var="enable_deletion_protection=false" -auto-approve || true

echo ""
echo "Disabling deletion protection on RDS..."
# terraform apply -target=module.rds -var="deletion_protection=false" -auto-approve || true

echo ""
echo "Running terraform destroy..."
echo ""

terraform destroy

echo ""
echo "=========================================="
echo "  Production environment destroyed!"
echo "=========================================="
