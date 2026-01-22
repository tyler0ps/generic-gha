output "namespace" {
  description = "ArgoCD namespace"
  value       = helm_release.argocd.namespace
}

output "release_name" {
  description = "Helm release name"
  value       = helm_release.argocd.name
}

output "admin_password_command" {
  description = "Command to retrieve ArgoCD admin password"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
}

output "server_service" {
  description = "ArgoCD server service name"
  value       = "argocd-server"
}
