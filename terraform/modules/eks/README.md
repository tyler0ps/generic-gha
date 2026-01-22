# EKS Module

A cost-optimized Amazon EKS (Elastic Kubernetes Service) module with Karpenter autoscaling.

## Features

### Current Implementation (Phase 1)

- **EKS Cluster**
  - Kubernetes version: 1.31+ (configurable)
  - Public and private API endpoint access
  - IRSA (IAM Roles for Service Accounts) enabled
  - Cluster add-ons: CoreDNS, VPC CNI (with prefix delegation), kube-proxy, EKS Pod Identity Agent

- **Karpenter Autoscaling**
  - Version: 1.8.5
  - Spot instance prioritization for 70-90% cost savings
  - Automatic node consolidation (removes idle nodes after 30s)
  - Instance types: c, m, r families (generation 5+)
  - Instance sizes: medium, large, xlarge
  - Architecture: amd64
  - AMI: Amazon Linux 2023 (AL2023)
  - Spot interruption handling via SQS queue

- **Managed Node Group**
  - Single m5.large SPOT instance for Karpenter controller
  - Cost-optimized: ~$0.048/hour (~$35/month)
  - Tagged for Karpenter discovery

- **Security**
  - Separate IAM roles for Karpenter controller and managed nodes
  - Node security group tagged for auto-discovery
  - Private subnet enforcement for Karpenter nodes

## Usage

### Basic Example

```hcl
module "eks" {
  source = "../../modules/eks"

  project     = "my-project"
  environment = "staging"

  cluster_version = "1.34"

  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  tags = {
    Environment = "staging"
    ManagedBy   = "Terraform"
  }
}
```

### Deploying Workloads

Workloads will automatically be scheduled by Karpenter on cost-optimized SPOT instances:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: my-app
        image: nginx:latest
        resources:
          requests:
            cpu: 1
            memory: 1Gi
```

Karpenter will automatically:
1. Provision the right-sized EC2 instances
2. Use SPOT instances when available
3. Consolidate nodes when workload decreases
4. Handle SPOT interruptions gracefully

## Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project` | string | required | Project name |
| `environment` | string | required | Environment name (staging, production) |
| `cluster_version` | string | `"1.31"` | Kubernetes version |
| `vpc_id` | string | required | VPC ID where cluster will be deployed |
| `private_subnets` | list(string) | required | Private subnet IDs for the cluster |
| `cluster_endpoint_public_access` | bool | `true` | Enable public API server endpoint |
| `cluster_endpoint_private_access` | bool | `true` | Enable private API server endpoint |
| `enable_cluster_encryption` | bool | `false` | Enable encryption for Kubernetes secrets using KMS |
| `kms_key_arn` | string | `""` | ARN of KMS key for cluster encryption |
| `karpenter_version` | string | `"1.8.5"` | Version of Karpenter to install |
| `tags` | map(string) | `{}` | Additional tags for resources |

## Outputs

| Output | Description |
|--------|-------------|
| `cluster_id` | EKS cluster ID |
| `cluster_name` | EKS cluster name |
| `cluster_arn` | EKS cluster ARN |
| `cluster_endpoint` | Endpoint for EKS control plane |
| `cluster_security_group_id` | Security group ID attached to the cluster |
| `cluster_certificate_authority_data` | Base64 encoded certificate data |
| `cluster_version` | Kubernetes server version |
| `oidc_provider_arn` | ARN of the OIDC Provider for IRSA |
| `node_security_group_id` | Security group ID attached to nodes |
| `karpenter_irsa_arn` | ARN of IAM role for Karpenter controller |
| `karpenter_instance_profile_name` | Name of instance profile for Karpenter nodes |
| `karpenter_queue_name` | Name of SQS queue for SPOT termination handling |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      VPC                                │
├─────────────────────────────────────────────────────────┤
│  Public Subnets          Private Subnets                │
│  (NAT Gateway)          (Karpenter Nodes)               │
│         ↓                      ↓                         │
│   ┌──────────────┐      ┌──────────────┐                │
│   │ EKS Control  │      │ Worker Nodes │                │
│   │ Plane        │      │              │                │
│   └──────────────┘      │ ┌──────────┐ │                │
│                         │ │ Managed  │ │                │
│                         │ │ Node     │ │                │
│                         │ │ Group    │ │                │
│                         │ │ (1x m5.  │ │                │
│                         │ │  large   │ │                │
│                         │ │  SPOT)   │ │                │
│                         │ │          │ │                │
│                         │ │ Karpenter│ │                │
│                         │ │ Controller│ │               │
│                         │ └──────────┘ │                │
│                         │              │                │
│                         │ ┌──────────┐ │                │
│                         │ │ Karpenter│ │                │
│                         │ │ Managed  │ │                │
│                         │ │ Nodes    │ │                │
│                         │ │ (SPOT)   │ │                │
│                         │ └──────────┘ │                │
│                         └──────────────┘                │
│                                ↓                         │
│                         SQS Queue (SPOT                  │
│                          Interruptions)                  │
└─────────────────────────────────────────────────────────┘
```

## Cost Optimization

### Current Costs (Staging)

| Component | Monthly Cost | Notes |
|-----------|--------------|-------|
| EKS Control Plane | ~$73 | Fixed cost |
| Managed Node Group | ~$35 | 1x m5.large SPOT |
| Karpenter Nodes | Variable | SPOT instances, scales to zero |
| NAT Gateway | ~$32 | Required for private subnets |
| **Total Baseline** | **~$140** | Minimum cost |

### Cost Saving Features

1. **SPOT Instances**: 70-90% savings vs on-demand
2. **Karpenter Consolidation**: Removes idle nodes after 30s
3. **Right-sizing**: Provisions exactly what workloads need
4. **Single NAT Gateway**: Shared across AZs in staging

## Karpenter Configuration

### NodePool Settings

- **Instance Categories**: c (compute), m (general), r (memory-optimized)
- **Instance Generation**: 5+ (newer = better price/performance)
- **Instance Sizes**: medium, large, xlarge
- **Capacity Type**: SPOT preferred, on-demand fallback
- **Architecture**: amd64
- **OS**: Linux (Amazon Linux 2023)
- **AMI**: Latest EKS-optimized AL2023
- **Consolidation**: After 30s of underutilization
- **Disruption Budget**: Max 10% of nodes at once

### Customizing NodePool

To customize the NodePool requirements, edit [karpenter-nodepool.tf](karpenter-nodepool.tf).

Example: Add GPU instances for ML workloads:

```yaml
requirements:
  - key: karpenter.k8s.aws/instance-category
    operator: In
    values: ["c", "m", "r", "g", "p"]  # Added g, p for GPU
```

## Cluster Access

### Configure kubectl

```bash
aws eks update-kubeconfig --name <project>-<environment> --region ap-southeast-1
```

### Verify Cluster

```bash
kubectl get nodes
kubectl get pods -n kube-system
```

### Check Karpenter

```bash
# Karpenter controller
kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter

# NodePool configuration
kubectl get nodepool

# EC2NodeClass configuration
kubectl get ec2nodeclass
```

## Testing Karpenter

### Deploy Test Workload

```bash
# Create deployment that requires 3 nodes
kubectl create deployment test-karpenter --image=nginx --replicas=3
kubectl set resources deployment test-karpenter --requests=cpu=1,memory=1Gi

# Watch Karpenter provision nodes
kubectl get nodes -w
```

### Verify Scaling

```bash
# Check node details
kubectl get nodes -o wide

# Check instance types
kubectl get nodes -o json | jq -r '.items[] | "\(.metadata.name): \(.metadata.labels["node.kubernetes.io/instance-type"])"'

# Check architecture
kubectl get nodes -o json | jq -r '.items[] | "\(.metadata.name): \(.metadata.labels["kubernetes.io/arch"])"'
```

### Test Consolidation

```bash
# Delete deployment
kubectl delete deployment test-karpenter

# Watch nodes get removed after 30s
kubectl get nodes -w
```

### Monitor Karpenter Logs

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter --tail=50 -f
```

## Phase 2 Features (Future Implementation)

The following features will be implemented when setting up ArgoCD and GitOps workflows:

### Fargate Profiles

Fargate will be used for specific workloads that benefit from serverless compute:

- **ArgoCD**: GitOps controller on Fargate
- **External Secrets Operator**: Secret management on Fargate
- **Batch Jobs**: Database migrations, one-time jobs

**Benefits:**
- No node management overhead
- Isolated compute per pod
- Pay only for pod runtime

### IRSA (IAM Roles for Service Accounts)

IRSA will provide fine-grained IAM permissions to Kubernetes workloads:

- **External Secrets Operator**: Access to AWS Secrets Manager/SSM Parameter Store
- **AWS Load Balancer Controller**: Manage ALB/NLB for ingress
- **Application Workloads**: S3, RDS, DynamoDB access

**Benefits:**
- No IAM credentials in pods
- Least-privilege security model
- Automatic credential rotation

### ArgoCD Integration

ArgoCD will be deployed for GitOps-based continuous delivery:

- **Git as Source of Truth**: All Kubernetes manifests in Git
- **Automated Sync**: Automatic deployment on Git commit
- **Rollback**: Easy rollback to previous versions
- **Multi-Environment**: Dev, staging, production environments

## Prerequisites

### VPC Requirements

The VPC must have:
- Private subnets tagged with:
  - `karpenter.sh/discovery: <project>-<environment>`
  - `kubernetes.io/role/internal-elb: "1"`
- Public subnets for NAT Gateway
- Internet Gateway for public subnets
- NAT Gateway for private subnet internet access

### AWS Permissions

The Terraform execution role needs permissions for:
- EKS cluster creation and management
- EC2 instance management (for Karpenter)
- IAM role and policy creation
- SQS queue creation
- VPC resource management

## Troubleshooting

### Karpenter Not Provisioning Nodes

1. Check Karpenter controller logs:
   ```bash
   kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter --tail=100
   ```

2. Verify NodePool is active:
   ```bash
   kubectl get nodepool
   kubectl describe nodepool default
   ```

3. Check subnet tags:
   ```bash
   aws ec2 describe-subnets --filters "Name=tag:karpenter.sh/discovery,Values=<project>-<environment>"
   ```

### Pods Not Scheduling

1. Check pod events:
   ```bash
   kubectl describe pod <pod-name>
   ```

2. Verify resource requests are within NodePool limits:
   - Max CPU: 100 cores
   - Max Memory: 200Gi

3. Check if pod has node affinity/anti-affinity constraints

### High Costs

1. Check idle nodes:
   ```bash
   kubectl get nodes -o json | jq '.items[] | {name: .metadata.name, pods: .status.allocatable}'
   ```

2. Verify consolidation is working:
   ```bash
   kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter | grep consolidation
   ```

3. Review NodePool disruption settings in [karpenter-nodepool.tf](karpenter-nodepool.tf)

## References

- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Karpenter Documentation](https://karpenter.sh/)
- [Karpenter v1 Migration Guide](https://karpenter.sh/docs/upgrading/v1-migration/)
- [EKS Cost Optimization](https://aws.amazon.com/blogs/containers/cost-optimization-for-kubernetes-on-aws/)

## Migration from karpenter-experiment

This module is based on the validated configuration from `terraform/karpenter-experiment`. The key improvements in this production module:

- Modular design for reuse across environments
- Configurable variables for flexibility
- Proper dependency management
- Comprehensive documentation
- Phase 2 roadmap for future enhancements

## Contributing

When making changes to this module:

1. Test changes in `karpenter-experiment` first
2. Update this module after validation
3. Update the README with any new features
4. Increment Karpenter version only after testing
5. Document breaking changes in migration notes
