output "argocd_deploy_keys_public" {
  description = "Map of owner/repo → SSH public key. Add each key as a read-only Deploy Key in the corresponding GitHub repo settings."
  value       = { for k, v in tls_private_key.argocd_repo_key : k => v.public_key_openssh }
}
