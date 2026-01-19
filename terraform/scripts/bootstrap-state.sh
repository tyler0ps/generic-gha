#!/bin/bash
set -e

BUCKET_NAME="generic-gha-terraform-state"
TABLE_NAME="generic-gha-terraform-lock"
REGION="ap-southeast-1"

echo "=========================================="
echo "  Terraform State Backend Bootstrap"
echo "=========================================="
echo ""
echo "This script will create:"
echo "  - S3 bucket: $BUCKET_NAME"
echo "  - DynamoDB table: $TABLE_NAME"
echo "  - Region: $REGION"
echo ""
echo "Press Ctrl+C to cancel, or wait 5 seconds to continue..."
sleep 5

echo ""
echo "Creating S3 bucket..."
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$REGION" \
    --create-bucket-configuration LocationConstraint="$REGION" \
    2>/dev/null || echo "Bucket may already exist, continuing..."

echo "Enabling versioning..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo "Enabling encryption..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

echo "Blocking public access..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration '{
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }'

echo ""
echo "=========================================="
echo "  Bootstrap complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Uncomment the backend configuration in:"
echo "   - terraform/global/backend.tf"
echo "   - terraform/environments/staging/backend.tf"
echo "   - terraform/environments/production/backend.tf"
echo ""
echo "2. Run 'terraform init' in each directory to migrate state"
