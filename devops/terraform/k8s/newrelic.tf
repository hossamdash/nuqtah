resource "helm_release" "newrelic_bundle" {
  chart            = "nri-bundle"
  name             = "newrelic-bundle"
  repository       = "https://helm-charts.newrelic.com"
  namespace        = "newrelic"
  create_namespace = true

  values = [
    templatefile("${path.module}/templates/new-relic-values.yaml", {
      newrelic_license_key = var.NEWRELIC_LICENSE_KEY
    }),
  ]
}
