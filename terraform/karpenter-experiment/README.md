# Karpenter Experiment

A standalone, from-scratch Karpenter experiment on Amazon EKS. This setup follows the [official Karpenter getting started guide](https://karpenter.sh/docs/getting-started/getting-started-with-karpenter/) and converts all steps to Infrastructure as Code using Terraform.

## What is Karpenter?

Karpenter is a flexible, high-performance Kubernetes cluster autoscaler that automatically provisions right-sized compute resources in response to changing application demands. Unlike traditional cluster autoscalers, Karpenter:

- Provisions nodes in seconds, not minutes
- Optimizes for cost by selecting appropriate instance types
- Consolidates underutilized nodes automatically
- Handles spot interruptions gracefully

## Architecture

This experiment creates:

- **New VPC** (10.2.0.0/16) - Completely isolated from other infrastructure
- **EKS Cluster** (Kubernetes 1.34) - Fresh cluster for experimentation
- **Karpenter** (v1.8.5) - Installed via Helm with IRSA
- **Initial Node Group** - 2x m5.large spot instances for Karpenter controller
- **NodePool Configuration** - Defines how Karpenter provisions nodes
- **Test Deployment** - nginx workload to trigger autoscaling

## Prerequisites

Before you begin, ensure you have:

1. **AWS CLI** configured with credentials
   ```bash
   aws configure
   aws sts get-caller-identity
   ```

2. **Terraform** (>= 1.0)
   ```bash
   terraform version
   ```

3. **kubectl** (Kubernetes CLI)
   ```bash
   kubectl version --client
   ```

4. **Sufficient AWS permissions** to create:
   - VPC, Subnets, NAT Gateways
   - EKS Clusters
   - IAM Roles and Policies
   - EC2 Instances
   - SQS Queues

## Quick Start

### 1. Deploy the Infrastructure

```bash
# Navigate to the experiment directory
cd terraform/karpenter-experiment

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

The deployment takes approximately 15-20 minutes.

### 2. Configure kubectl

After successful deployment, configure kubectl to access your cluster:

```bash
# Configure kubectl (command shown in terraform output)
aws eks update-kubeconfig --name karpenter-experiment --region ap-southeast-1

# Verify cluster access
kubectl cluster-info
kubectl get nodes
```

### 3. Verify Karpenter Installation

```bash
# Check Karpenter pods
kubectl get pods -n kube-system -l app.kubernetes.io/name=karpenter

# View Karpenter logs
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter --tail=50

# Verify Karpenter CRDs
kubectl get nodepools
kubectl get ec2nodeclasses
```

### 4. Test Autoscaling

The deployment includes a test nginx workload. Let's test Karpenter:

```bash
# Check current state
kubectl get nodes
kubectl get pods -n test -o wide

# Scale up to trigger node provisioning
kubectl scale deployment nginx-test -n test --replicas=5

# In another terminal, watch Karpenter logs
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter -f

# Watch nodes being created
kubectl get nodes --watch
```

You should see Karpenter:
1. Detect unschedulable pods
2. Calculate optimal instance types
3. Provision new EC2 instances
4. Register them as nodes
5. Schedule pods on the new nodes

### 5. Test Consolidation

Karpenter automatically removes underutilized nodes:

```bash
# Scale down
kubectl scale deployment nginx-test -n test --replicas=1

# Watch Karpenter consolidate (remove unnecessary nodes)
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter -f

# Observe nodes being drained and terminated
kubectl get nodes --watch
```

## Understanding the Configuration

### NodePool Configuration

The default NodePool ([nodepool.tf](nodepool.tf)) defines:

- **Instance Types**: c, m, r families (compute, memory, general)
- **Instance Generations**: > 4 (newer generations)
- **Capacity Type**: Spot preferred, on-demand fallback
- **Architecture**: amd64
- **Size Range**: medium to xlarge
- **Limits**: Max 100 CPUs, 200Gi memory
- **Consolidation**: WhenEmptyOrUnderutilized

### EC2NodeClass Configuration

The EC2NodeClass defines AWS-specific settings:

- **AMI Family**: AL2023 (Amazon Linux 2023)
- **Subnets**: Discovered via tags (`karpenter.sh/discovery`)
- **Security Groups**: Discovered via tags
- **IAM Role**: Karpenter node role with required permissions

## Experiments to Try

### 1. Different Instance Types

Modify the NodePool requirements in [nodepool.tf](nodepool.tf):

```yaml
# Try GPU instances
- key: karpenter.k8s.aws/instance-category
  operator: In
  values: ["g", "p"]

# Try ARM instances
- key: kubernetes.io/arch
  operator: In
  values: ["arm64"]
```

### 2. Multiple NodePools

Create specialized pools for different workloads:

```yaml
# High-performance pool
- key: karpenter.k8s.aws/instance-category
  operator: In
  values: ["c"]  # Compute-optimized only
```

### 3. Spot Interruption Handling

```bash
# Deploy workload on spot
kubectl apply -f your-workload.yaml

# Karpenter automatically handles spot interruptions via SQS
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter -f
```

### 4. Custom Resource Requests

Create a deployment with specific requirements:

```yaml
resources:
  requests:
    cpu: "4"
    memory: "8Gi"
```

Watch Karpenter select appropriate instance types.

## Useful Commands

### View Node Details

```bash
# Show node labels
kubectl get nodes --show-labels

# Show nodes with Karpenter information
kubectl get nodes -L karpenter.sh/nodepool,node.kubernetes.io/instance-type,karpenter.sh/capacity-type

# Describe a node
kubectl describe node <node-name>
```

### Monitor Karpenter

```bash
# View Karpenter events
kubectl get events -n kube-system --field-selector source=karpenter

# View Karpenter metrics (if metrics-server is installed)
kubectl top nodes

# Describe NodePool
kubectl describe nodepool default
```

### Debugging

```bash
# Check Karpenter controller status
kubectl get deployment -n kube-system karpenter

# View all Karpenter resources
kubectl get nodepools,ec2nodeclasses

# Check for errors in Karpenter logs
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter --tail=100 | grep -i error
```

## Cost Optimization

### Estimated Monthly Costs

- **EKS Control Plane**: $73/month (fixed)
- **Initial Nodes** (2x m5.large spot): ~$20-25/month
- **NAT Gateway**: ~$32/month
- **Karpenter-managed Nodes**: Variable based on workload
- **Total Baseline**: ~$125-130/month

### Cost-Saving Tips

1. **Destroy when not in use**
   ```bash
   terraform destroy
   ```

2. **Use Spot instances** (already configured)
   - 70-90% cheaper than on-demand
   - Karpenter handles interruptions gracefully

3. **Enable consolidation** (already configured)
   - Automatically removes underutilized nodes
   - Saves money by reducing idle capacity

4. **Set appropriate limits**
   - Prevents runaway scaling
   - Configure in NodePool `limits` section

## Troubleshooting

### Karpenter not provisioning nodes?

```bash
# Check Karpenter logs
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter -f

# Check NodePool configuration
kubectl describe nodepool default

# Check for pending pods
kubectl get pods -A | grep Pending

# Verify IRSA configuration
kubectl describe sa karpenter -n kube-system
```

### Nodes not joining the cluster?

```bash
# Check EC2 instances in AWS console
aws ec2 describe-instances --filters "Name=tag:karpenter.sh/nodepool,Values=default"

# Check node IAM role
aws iam get-role --role-name <karpenter-node-role-name>

# View EC2 instance logs (Systems Manager required)
aws ssm start-session --target <instance-id>
```

### Terraform errors?

```bash
# Reinitialize providers
terraform init -upgrade

# Refresh state
terraform refresh

# Check for provider version issues
terraform version
```

## Cleanup

When you're done experimenting:

```bash
# Navigate to the experiment directory
cd terraform/karpenter-experiment

# Destroy all resources
terraform destroy

# Confirm destruction
# Type 'yes' when prompted
```

This will:
1. Delete the test deployment
2. Remove Karpenter-managed nodes
3. Uninstall Karpenter
4. Delete the EKS cluster
5. Remove the VPC and networking resources

## Files in This Directory

| File | Purpose |
|------|---------|
| [backend.tf](backend.tf) | S3 backend configuration for Terraform state |
| [providers.tf](providers.tf) | AWS, Kubernetes, Helm, kubectl provider configuration |
| [locals.tf](locals.tf) | Local variables (cluster name, region, VPC CIDR) |
| [main.tf](main.tf) | VPC and EKS cluster configuration |
| [karpenter.tf](karpenter.tf) | Karpenter IAM roles and Helm installation |
| [nodepool.tf](nodepool.tf) | NodePool and EC2NodeClass definitions |
| [test-deployment.tf](test-deployment.tf) | nginx test workload |
| [outputs.tf](outputs.tf) | Terraform outputs with useful commands |
| [README.md](README.md) | This file |

## Additional Resources

- [Karpenter Official Documentation](https://karpenter.sh/docs/)
- [Karpenter Best Practices](https://aws.github.io/aws-eks-best-practices/karpenter/)
- [EKS Workshop - Karpenter](https://www.eksworkshop.com/docs/autoscaling/compute/karpenter/)
- [Karpenter GitHub](https://github.com/aws/karpenter)

## Next Steps

1. Experiment with different NodePool configurations
2. Test spot interruption handling
3. Try multiple NodePools for different workload types
4. Measure cost savings compared to traditional autoscaling
5. Test with your actual workloads

## Notes

- This is an **experiment environment** - not for production use
- All resources are tagged with `Project=karpenter-experiment`
- The setup is completely isolated from your existing infrastructure
- State is stored separately at `experiments/karpenter-experiment/terraform.tfstate`
- You can safely destroy and recreate this environment at any time

---

**Happy Experimenting with Karpenter!** 🚀
