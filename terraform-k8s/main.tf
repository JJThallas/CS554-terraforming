terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
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


module "nginx" {
  source    = "./modules/nginx"
  namespace = module.namespace.name
}

module "second" {
  source    = "./modules/second"
  namespace = module.namespace.name
}