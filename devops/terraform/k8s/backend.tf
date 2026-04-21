terraform {
  backend "s3" {
    bucket = "nuqtah-terraform-state"
    key    = "k8s"

    # Use S3 native locking (requires Terraform >= 1.10)
    use_lockfile = true

    profile = "kumo"
    region  = "eu-west-1"

    # Kumo compatibility flags
    endpoints = { s3 = "http://localhost:4566" }

    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_region_validation      = true
    force_path_style            = true
  }
}
