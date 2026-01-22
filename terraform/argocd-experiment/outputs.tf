# ============================================================
# OUTPUTS - Cluster and ArgoCD Access Information
# ============================================================

output "cluster_name" {
  description = "EKS cluster name (from karpenter-experiment)"
  value       = data.terraform_remote_state.karpenter_experiment.outputs.cluster_name
}

output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = local.argocd_namespace
}

output "gitops_repo_url" {
  description = "GitOps repository URL"
  value       = local.gitops_repo_url
}

# ============================================================
# DEPLOY KEY - Add this to GitHub repository
# ============================================================

output "deploy_key_public" {
  description = "Public SSH key - Add this as a deploy key to your GitOps repository"
  value       = tls_private_key.argocd_repo.public_key_openssh
  sensitive   = false
}

# ============================================================
# SETUP INSTRUCTIONS
# ============================================================

output "setup_instructions" {
  description = "Step-by-step setup instructions"
  value       = <<-EOT

    ============================================================
    ARGOCD EXPERIMENT - SETUP INSTRUCTIONS
    ============================================================

    Cluster: ${data.terraform_remote_state.karpenter_experiment.outputs.cluster_name}
    Region: ${local.region}
    ArgoCD Namespace: ${local.argocd_namespace}
    GitOps Repository: ${local.gitops_repo_url}

    ============================================================
    STEP 1: Configure kubectl
    ============================================================
    aws eks update-kubeconfig --name ${data.terraform_remote_state.karpenter_experiment.outputs.cluster_name} --region ${local.region}

    ============================================================
    STEP 2: Add Deploy Key to GitHub
    ============================================================
    1. Copy the public key:
       terraform output deploy_key_public

    2. Go to: https://github.com/tyler0ps/application-gitops/settings/keys

    3. Click "Add deploy key"

    4. Title: "ArgoCD Experiment Deploy Key"

    5. Paste the public key

    6. Select "Read access" (write access not needed)

    7. Click "Add key"

    ============================================================
    STEP 3: Verify ArgoCD Installation
    ============================================================
    # Check ArgoCD pods
    kubectl get pods -n ${local.argocd_namespace}

    # Expected: controller, server, repo-server, redis pods running

    ============================================================
    STEP 4: Access ArgoCD UI
    ============================================================
    # Get initial admin password
    kubectl -n ${local.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

    # Port-forward to ArgoCD UI (in a separate terminal)
    kubectl port-forward svc/argocd-server -n ${local.argocd_namespace} 8080:443

    # Access UI at: http://localhost:8080
    # Username: admin
    # Password: <from command above>

    ============================================================
    STEP 5: Verify Applications
    ============================================================
    # Check ArgoCD Applications
    kubectl get applications -n ${local.argocd_namespace}

    # Expected: root, infrastructure-apps, services-apps, demo-nginx, demo-redis

    # Check sample app pods
    kubectl get pods -n demo-apps

    # Watch application sync status
    kubectl get applications -n ${local.argocd_namespace} --watch

    ============================================================
    ARGOCD CLI (Optional)
    ============================================================
    # Install ArgoCD CLI (if not already installed)
    # brew install argocd  # macOS
    # Or download from: https://argo-cd.readthedocs.io/en/stable/cli_installation/

    # Login to ArgoCD
    argocd login localhost:8080 --username admin --password <password> --insecure

    # List applications
    argocd app list

    # Get application details
    argocd app get demo-nginx

    # Sync application manually
    argocd app sync demo-redis

    ============================================================
    EXPERIMENTS TO TRY
    ============================================================
    1. Auto-sync test (demo-nginx):
       - Edit: ${local.gitops_repo_path}/services/demo-nginx/base/deployment.yaml
       - Change replicas from 2 to 5
       - Commit and push
       - Watch ArgoCD sync automatically

    2. Manual sync test (demo-redis):
       - Edit: ${local.gitops_repo_path}/services/demo-redis/deployment.yaml
       - Change image tag
       - Commit and push
       - Manually sync in UI

    3. Self-healing test:
       - kubectl scale deployment demo-nginx -n demo-apps --replicas=10
       - Watch ArgoCD detect drift and correct it

    4. Rollback test:
       - Make a breaking change (invalid image tag)
       - Let it sync and fail
       - Use UI to rollback to previous version

    ============================================================
    COST ESTIMATE
    ============================================================
    ArgoCD runs on existing karpenter-experiment cluster:
    - No additional infrastructure costs
    - ArgoCD pods: ~1 CPU, 2GB RAM total
    - Karpenter provisions spot instances as needed

    Existing cluster cost: ~$125-130/month
    - EKS control plane: $73/month
    - Base nodes: ~$20-25/month (spot)
    - NAT Gateway: ~$32/month

    ============================================================
    CLEANUP
    ============================================================
    # Remove ArgoCD from cluster
    cd terraform/argocd-experiment
    terraform destroy

    # This leaves karpenter-experiment cluster running
    # To remove everything:
    cd ../karpenter-experiment
    terraform destroy

    ============================================================
    TROUBLESHOOTING
    ============================================================
    # Repository connection issues
    kubectl get secret argocd-gitops-repo -n ${local.argocd_namespace}
    kubectl logs -n ${local.argocd_namespace} deployment/argocd-repo-server

    # Application sync issues
    kubectl describe application root -n ${local.argocd_namespace}
    kubectl logs -n ${local.argocd_namespace} deployment/argocd-application-controller

    # Pod scheduling issues
    kubectl get events -n ${local.argocd_namespace}
    kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter

  EOT
}

# ============================================================
# QUICK ACCESS COMMANDS
# ============================================================

output "quick_commands" {
  description = "Quick reference commands"
  value       = <<-EOT
    # Configure kubectl
    aws eks update-kubeconfig --name ${data.terraform_remote_state.karpenter_experiment.outputs.cluster_name} --region ${local.region}

    # Get ArgoCD admin password
    kubectl -n ${local.argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

    # Port-forward to ArgoCD UI
    kubectl port-forward svc/argocd-server -n ${local.argocd_namespace} 8080:443

    # View applications
    kubectl get applications -n ${local.argocd_namespace}

    # View demo app pods
    kubectl get pods -n demo-apps
  EOT
}
