# Infrastructure Layer

## Purpose

This layer contains **long-lived infrastructure** that rarely changes:
- VPC and networking (subnets, NAT gateway, internet gateway)
- RDS PostgreSQL database
- Security groups for database access

## When to Apply

- **Initial setup**: Once when creating the environment
- **Rare changes**: When you need to modify VPC or RDS settings
- **Keep running**: Don't destroy this layer during normal development

## Usage

```bash
# Initialize
terraform init

# Plan changes
terraform plan

# Apply (takes ~10 minutes due to RDS)
terraform apply

# View outputs (used by compute layer)
terraform output
```

## Outputs

This layer exports outputs consumed by the compute layer:
- VPC ID and subnets
- Security group IDs
- RDS connection details (via SSM Parameter Store)

## Cost

**~$16/month**
- VPC: Free (NAT Gateway ~$32/month, but using single NAT for cost saving)
- RDS db.t3.micro: ~$13/month
- Storage: ~$3/month

## Cost Savings: Stop/Start RDS

Instead of destroying, you can **stop RDS** when not in use to save costs:

```bash
# Stop RDS (saves ~$13/month, keeps storage)
terraform output -raw rds_stop_command | bash

# Check status
terraform output -raw rds_status_command | bash

# Start RDS when needed
terraform output -raw rds_start_command | bash

# View all management commands
terraform output rds_management_info
```

**Cost breakdown:**
- Running: $16/month (instance $13 + storage $3)
- Stopped: $3/month (storage only)
- **Savings: $13/month** when stopped

⚠️ **Note**: AWS automatically restarts RDS after 7 days of being stopped.

## Destruction

⚠️ **Only destroy when tearing down the entire environment**

```bash
# WARNING: This will delete your database!
terraform destroy  # Takes ~10-12 minutes
```
