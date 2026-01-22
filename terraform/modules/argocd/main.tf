# ============================================================
# ARGOCD HELM RELEASE
# ============================================================

resource "helm_release" "argocd" {
  namespace        = "argocd"
  create_namespace = true
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.3.3"

  values = [yamlencode({
    controller = {
      nodeSelector = {
        "karpenter.sh/capacity-type" = "spot"
      }
      resources = {
        requests = { cpu = "250m", memory = "512Mi" }
        limits   = { cpu = "500m", memory = "1Gi" }
      }
    }

    server = {
      nodeSelector = {
        "karpenter.sh/capacity-type" = "spot"
      }
      resources = {
        requests = { cpu = "250m", memory = "256Mi" }
        limits   = { cpu = "500m", memory = "512Mi" }
      }
      ingress = {
        enabled          = true
        ingressClassName = "alb"
        annotations = {
          "alb.ingress.kubernetes.io/scheme"       = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"  = "ip"
          "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\": 80}]"
          "alb.ingress.kubernetes.io/group.name"   = "argocd-${var.environment}"
        }
        hosts = []
      }
    }

    repoServer = {
      nodeSelector = {
        "karpenter.sh/capacity-type" = "spot"
      }
      resources = {
        requests = { cpu = "250m", memory = "256Mi" }
        limits   = { cpu = "500m", memory = "512Mi" }
      }
    }

    configs = {
      params = {
        "server.insecure" = true
      }
    }
  })]

  depends_on = [var.cluster_id]
}
