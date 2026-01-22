# ============================================================
# ARGOCD NAMESPACE
# ============================================================

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = local.argocd_namespace

    labels = {
      name    = local.argocd_namespace
      purpose = "gitops-controller"
    }
  }
}

# ============================================================
# ARGOCD HELM RELEASE
# Install ArgoCD for GitOps workflow
# ============================================================

resource "helm_release" "argocd" {
  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = local.argocd_version

  # Wait for deployment to be ready
  wait    = true
  timeout = 600

  values = [yamlencode({
    # ============================================================
    # CONTROLLER CONFIGURATION
    # Manages application state reconciliation
    # ============================================================
    controller = {
      # Run on Karpenter-managed spot instances
      nodeSelector = {
        "karpenter.sh/capacity-type" = "spot"
      }

      # Resource limits for controller
      resources = {
        requests = {
          cpu    = "250m"
          memory = "512Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "1Gi"
        }
      }
    }

    # ============================================================
    # SERVER CONFIGURATION
    # Provides UI and API access
    # ============================================================
    server = {
      # Run on Karpenter-managed spot instances
      nodeSelector = {
        "karpenter.sh/capacity-type" = "spot"
      }

      # Resource limits for server
      resources = {
        requests = {
          cpu    = "250m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }

      # Disable ingress - use kubectl port-forward for access
      ingress = {
        enabled = false
      }

      # Expose service for port-forwarding
      service = {
        type = "ClusterIP"
      }
    }

    # ============================================================
    # REPO SERVER CONFIGURATION
    # Handles Git repository interactions
    # ============================================================
    repoServer = {
      # Run on Karpenter-managed spot instances
      nodeSelector = {
        "karpenter.sh/capacity-type" = "spot"
      }

      # Resource limits for repo server
      resources = {
        requests = {
          cpu    = "250m"
          memory = "256Mi"
        }
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
      }
    }

    # ============================================================
    # ARGOCD CONFIGURATION
    # ============================================================
    configs = {
      params = {
        # Run in insecure mode for easier port-forward access
        "server.insecure" = true
      }

      # Repository credentials will be added via separate Kubernetes Secret
      # See deploy-key.tf for SSH key configuration
    }
  })]

  depends_on = [kubernetes_namespace.argocd]
}
