terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "helm" {
  kubernetes = {
    config_path    = "/etc/rancher/k3s/k3s.yaml"
    config_context = "default"
  }
}

provider "kubectl" {
  config_path    = "/etc/rancher/k3s/k3s.yaml"
  config_context = "default"
}

provider "kubernetes" {
  config_path    = "/etc/rancher/k3s/k3s.yaml"
  config_context = "default"
}
