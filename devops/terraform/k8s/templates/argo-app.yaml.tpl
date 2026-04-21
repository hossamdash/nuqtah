apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${APP_NAME}
  namespace: argocd
spec:
  project: default
  destination:
    server: https://kubernetes.default.svc
    namespace: ${KUBERNETES_NAMESPACE}
  source:
    repoURL: git@github.com:${GITHUB_OWNER}/${GITHUB_REPO}.git
    path: devops/helm/charts/generic-app
    targetRevision: main
    helm:
      valueFiles:
        # path is relative to the chart path above
        - ../../apps/${APP_NAME}/values.yaml
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
