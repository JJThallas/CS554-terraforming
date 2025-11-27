terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "namespace" {
  source = "./modules/namespace"
  name   = "demo"
}

resource "helm_release" "nginx" {
  name       = "demo-nginx"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  namespace  = module.namespace.name
}
