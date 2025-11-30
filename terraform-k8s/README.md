# Terraforming with k3d

This directory contains all of the Terraform files for the Kubernetes version of my submission to Project 2 – Terraform.  
Instead of creating Docker containers directly, this configuration uses a Kubernetes cluster and creates:

- A demo Namespace
- An nginx Deployment
- An nginx Service
- Ingress (Trafik) objects

For my enhancement, I have added:

- A second (literally) Deployment
- A second (literally) Service

## Directory Overview

### /modules/namespace
Contains a module that creates a Kubernetes namespace and outputs its name so all resources are created in the same namespace.

### /modules/nginx
Contains a module that defines:
- `kubernetes_deployment` running an official [nginx image](https://hub.docker.com/_/nginx) on port 80.
- `kubernetes_service` that exposes the deployment outside the cluster.
- `kubernetes_ingress_v1` routes external HTTP traffic (via Traefik) to the service on host `demo.local`.

### /modules/second
Second deployment for enhancement. Contains a module that defines:
- `kubernetes_deployment` running [nginx's hello image](https://hub.docker.com/r/nginxdemos/hello/) on port 80.
- `kubernetes_service` that exposes the deployment outside the cluster.
- `kubernetes_ingress_v1` routes external HTTP traffic (via Traefik) to the service on host `second.local`.

### /values
Contains a replica count for nginx. I honestly didn't know this was here until writing this documentation, it came with the demo folder. I don't think I use it...

## Terraform Overview (main.tf resources)
Terraform requires a Kubernetes provider to do Kubernetes things.
```hcl
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
```

Declares this configuration uses a `kubernetes` and `helm` provider. The helm provider is currently unused.

### Module "namespace"
```hcl
module "namespace" {
  source = "./modules/namespace"
  name   = "demo"
}
```
Creates the namespace module and names it "demo" so all modules share the same namespace.


### Module "nginx"
```hcl
module "namespace" {
  source = "./modules/nginx"
  name   = module.namespace.name
}
```
Creates the nginx module in the current namespace. Nginx module definition is located at `/modules/nginx/main.tf`.

### Module "nginx"
```hcl
module "namespace" {
  source = "./modules/second"
  name   = module.namespace.name
}
```
Creates the second module in the current namespace. Second module definition is located at `/modules/second/main.tf`.

