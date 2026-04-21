variable "NEWRELIC_LICENSE_KEY" {
  description = "New Relic ingest license key (set via TF_VAR_NEWRELIC_LICENSE_KEY in .envrc)"
  type        = string
  sensitive   = true
}
