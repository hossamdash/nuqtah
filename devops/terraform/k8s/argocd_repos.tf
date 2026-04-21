# Derive unique repos from local.apps (one deploy key per repo, not per app).
locals {
  repos = {
    for app_key, app in local.apps :
    "${app.owner}/${app.repo}" => app
  }
}

# Generate one ED25519 SSH key pair per unique repo for ArgoCD to pull from GitHub.
# After applying, run: terraform output argocd_deploy_keys_public
# Then add each output as a Deploy Key (read-only) in the corresponding GitHub repo settings.
resource "tls_private_key" "argocd_repo_key" {
  for_each  = local.repos
  algorithm = "ED25519"
}

resource "kubernetes_secret" "argocd_repo_creds" {
  for_each = local.repos

  metadata {
    name      = "argocd-repo-creds-${each.value.repo}"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    "name"          = each.value.repo
    "sshPrivateKey" = tls_private_key.argocd_repo_key[each.key].private_key_openssh
    "type"          = "git"
    "url"           = "git@github.com:${each.key}.git"
  }

  depends_on = [
    helm_release.argocd,
  ]
}
