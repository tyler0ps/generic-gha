# ArgoCD Experiment

An isolated experiment deploying ArgoCD to the karpenter-experiment EKS cluster to learn GitOps workflows and ArgoCD capabilities.

## Overview

This experiment demonstrates:
- ArgoCD installation and configuration
- GitOps workflow with Git as source of truth
- App-of-Apps pattern for managing multiple applications
- Auto-sync vs manual-sync policies
- Self-healing and drift detection
- Rollback capabilities
- Kustomize integration

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Terraform: argocd-experiment/                               │
│  ├─ Reads karpenter-experiment cluster via remote state     │
│  ├─ Deploys ArgoCD via Helm                                 │
│  ├─ Generates SSH deploy key for GitOps repo                │
│  └─ Creates root App-of-Apps Application                    │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ deploys to
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  EKS Cluster: karpenter-experiment                          │
│  ├─ ArgoCD namespace with controller, server, repo-server   │
│  └─ Karpenter provisions nodes for ArgoCD pods              │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ pulls from
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  GitHub: application-gitops                                 │
│  ├─ bootstrap/ - App-of-Apps definitions                    │
│  ├─ infrastructure/ - Platform components                   │
│  └─ services/ - Sample applications                         │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **karpenter-experiment cluster** must be running
   ```bash
   cd ../karpenter-experiment
   terraform apply
   ```

2. **AWS CLI** configured with appropriate credentials

3. **kubectl** installed

4. **Terraform** >= 1.0

## Quick Start

### 1. Deploy ArgoCD

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

### 2. Add Deploy Key to GitHub

```bash
# Get the public SSH key
terraform output deploy_key_public

# Add it to GitHub:
# 1. Go to: https://github.com/tyler0ps/application-gitops/settings/keys
# 2. Click "Add deploy key"
# 3. Title: "ArgoCD Experiment Deploy Key"
# 4. Paste the public key
# 5. Select "Read access"
# 6. Click "Add key"
```

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --name karpenter-experiment --region ap-southeast-1
```

### 4. Access ArgoCD UI

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port-forward to UI (keep this running in a separate terminal)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser to: http://localhost:8080
# Username: admin
# Password: <from command above>
```

### 5. Verify Installation

```bash
# Check ArgoCD pods
kubectl get pods -n argocd

# Check applications
kubectl get applications -n argocd

# Check sample app pods
kubectl get pods -n demo-apps
```

## Sample Applications

### demo-nginx (Auto-sync)
- **Purpose**: Demonstrate automatic synchronization
- **Configuration**: Uses Kustomize with base + overlays
- **Sync Policy**: Automatic with prune and self-heal
- **Location**: `application-gitops/services/demo-nginx/`

### demo-redis (Manual-sync)
- **Purpose**: Demonstrate manual approval workflow
- **Configuration**: Raw Kubernetes manifests
- **Sync Policy**: Manual sync required
- **Location**: `application-gitops/services/demo-redis/`

## Educational Experiments

### Experiment 1: Auto-Sync (demo-nginx)

Test automatic synchronization:

```bash
# Edit the deployment
cd /Users/tyler0ps/workspace/second-layoff-spirit/application-gitops
# Change replicas from 2 to 5 in services/demo-nginx/base/deployment.yaml

git add .
git commit -m "Scale demo-nginx to 5 replicas"
git push

# Watch ArgoCD sync automatically (within 3 minutes)
kubectl get applications -n argocd --watch
kubectl get pods -n demo-apps --watch
```

### Experiment 2: Manual Sync (demo-redis)

Practice manual approval:

```bash
# Edit the deployment
# Change image tag in services/demo-redis/deployment.yaml

git add .
git commit -m "Update redis image"
git push

# In ArgoCD UI, observe "OutOfSync" status
# Click "Sync" button to approve
# Or use CLI:
argocd app sync demo-redis
```

### Experiment 3: Self-Healing

Test drift detection and correction:

```bash
# Manually change the cluster state
kubectl scale deployment demo-nginx -n demo-apps --replicas=10

# Watch ArgoCD detect drift and correct it
kubectl get applications -n argocd --watch

# demo-nginx should show "OutOfSync" then automatically heal back to Git state
```

### Experiment 4: Rollback

Test rollback capabilities:

```bash
# Make a breaking change
# Edit services/demo-nginx/base/deployment.yaml
# Change image to: nginx:invalid-tag

git add .
git commit -m "Break demo-nginx with invalid image"
git push

# Watch sync fail
# In ArgoCD UI:
# 1. Go to demo-nginx application
# 2. Click "History" tab
# 3. Select previous healthy revision
# 4. Click "Rollback"
```

### Experiment 5: Kustomize Overlays

Understand environment-specific configuration:

```bash
# Edit overlay configuration
# Modify services/demo-nginx/overlays/experiment/patches.yaml
# Add custom annotations or labels

git add .
git commit -m "Add custom labels via Kustomize"
git push

# Observe Kustomize applying the overlay
kubectl describe deployment demo-nginx -n demo-apps
```

## App-of-Apps Pattern

The experiment uses ArgoCD's App-of-Apps pattern:

```
root (bootstrap/)
├── infrastructure-apps
│   └── nginx-ingress (optional)
└── services-apps
    ├── demo-nginx (auto-sync)
    └── demo-redis (manual-sync)
```

The root application manages other applications, creating a hierarchical structure.

## Key Concepts Demonstrated

1. **GitOps Principles**
   - Git as single source of truth
   - Declarative configuration
   - Automated reconciliation

2. **ArgoCD Features**
   - Application management
   - Sync policies (auto vs manual)
   - Health assessment
   - Drift detection and self-healing
   - Rollback capabilities

3. **Kubernetes Patterns**
   - Kustomize for environment-specific config
   - Namespace management
   - Resource organization

## Cost Implications

**No additional costs** - ArgoCD runs on the existing karpenter-experiment cluster:
- ArgoCD pods: ~1 CPU, 2GB RAM total
- Karpenter auto-scales spot instances
- Scheduled on spot instances for cost savings

Existing cluster costs: ~$125-130/month
- EKS control plane: $73/month
- Base nodes: ~$20-25/month (spot)
- NAT Gateway: ~$32/month

## Troubleshooting

### Repository Connection Fails

```bash
# Check repository secret
kubectl get secret argocd-gitops-repo -n argocd -o yaml

# View repo-server logs
kubectl logs -n argocd deployment/argocd-repo-server

# Verify deploy key is added to GitHub
```

### Applications Not Syncing

```bash
# Check application status
kubectl describe application root -n argocd

# View controller logs
kubectl logs -n argocd deployment/argocd-application-controller

# Force refresh
argocd app get root --refresh
```

### Pods Not Scheduling

```bash
# Check Karpenter logs
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter

# Check NodePool
kubectl get nodepools

# View events
kubectl get events -n argocd
```

## Cleanup

To remove the experiment:

```bash
# Remove ArgoCD and all applications
terraform destroy

# This leaves the karpenter-experiment cluster running
# To remove the cluster as well:
cd ../karpenter-experiment
terraform destroy
```

## Next Steps

After mastering the basics, try:

1. **Add Ingress** - Expose applications via LoadBalancer
2. **Projects & RBAC** - Implement multi-team isolation
3. **ApplicationSets** - Dynamic application generation
4. **Sync Waves** - Control deployment order
5. **Secrets Management** - Integrate External Secrets Operator
6. **Image Updater** - Automate image tag updates
7. **Notifications** - Configure Slack/email alerts
8. **Multi-Cluster** - Deploy to multiple clusters
9. **Production Pattern** - Use src/rendered structure
10. **CI/CD Integration** - Trigger syncs from GitHub Actions

## Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [App-of-Apps Pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/)
- [Kustomize Documentation](https://kustomize.io/)
