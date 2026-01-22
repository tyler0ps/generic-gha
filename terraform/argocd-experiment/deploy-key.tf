# ============================================================
# SSH DEPLOY KEY GENERATION
# Creates SSH key pair for ArgoCD to access GitOps repository
# ============================================================

resource "tls_private_key" "argocd_repo" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ============================================================
# KUBERNETES SECRET FOR REPOSITORY ACCESS
# ArgoCD discovers repository credentials via label
# ============================================================

resource "kubernetes_secret" "argocd_repo" {
  metadata {
    name      = "argocd-gitops-repo"
    namespace = kubernetes_namespace.argocd.metadata[0].name

    labels = {
      # This label tells ArgoCD this is a repository credential
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type          = "git"
    url           = local.gitops_repo_url
    sshPrivateKey = tls_private_key.argocd_repo.private_key_openssh
  }

  depends_on = [helm_release.argocd]
}
