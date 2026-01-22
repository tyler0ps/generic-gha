# ============================================================
# ROOT APPLICATION (APP OF APPS)
# Manages all other ArgoCD Applications
# ============================================================

resource "kubectl_manifest" "root_app" {
  yaml_body = <<-YAML
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: root
      namespace: ${local.argocd_namespace}
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default

      source:
        repoURL: ${local.gitops_repo_url}
        targetRevision: main
        path: bootstrap
        directory:
          recurse: true

      destination:
        server: https://kubernetes.default.svc
        namespace: ${local.argocd_namespace}

      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  YAML

  depends_on = [
    helm_release.argocd,
    kubernetes_secret.argocd_repo
  ]
}
