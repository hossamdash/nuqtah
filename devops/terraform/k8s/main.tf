resource "helm_release" "argocd" {
  chart            = "argo-cd"
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  namespace        = "argocd"
  version          = "8.5.6"
  create_namespace = true

  values = [
    file("${path.module}/templates/argocd-values.yaml"),
  ]
}
