#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGING_DIR="${SCRIPT_DIR}/../environments/staging"

echo "=========================================="
echo "  STAGING ENVIRONMENT DESTRUCTION"
echo "=========================================="
echo ""
echo "WARNING: This will destroy ALL staging infrastructure including:"
echo "  - ECS Cluster and all services"
echo "  - RDS PostgreSQL database (ALL DATA WILL BE LOST)"
echo "  - VPC and networking components"
echo "  - ALB and target groups"
echo "  - CloudWatch log groups"
echo ""
echo "Press Ctrl+C to cancel, or wait 10 seconds to continue..."
sleep 10

cd "$STAGING_DIR"

echo ""
echo "Running terraform destroy..."
echo ""

terraform destroy -auto-approve

echo ""
echo "=========================================="
echo "  Staging environment destroyed!"
echo "=========================================="
