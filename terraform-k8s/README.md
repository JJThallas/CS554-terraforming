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

## "Quick" Start

1. Install Docker ([Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) for Windows, [Docker Engine](https://docs.docker.com/engine/install/) for Linux) and [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
2. Install kubectl:
```
sudo snap install kubectl --classic
```
3. Install k3d
```
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```
4. Create the k8s cluster (with load balancer):
```
k3d cluster create my-cluster --port "8080:80@loadbalancer"
```
5. Copy configuration files:
```
mkdir -p ~/.kube
k3d kubeconfig get demo-cluster > ~/.kube/config
chmod 600 ~/.kube/config
```
6. Test cluster:
```
kubectl config view
kubectl get nodes
```
7. Initialize terraform
```
terraform init
```
8. Apply terraform
```
terraform apply
```
9. Set Ingress
```
if ! grep -q 'demo.local' /etc/hosts; then
  echo '127.0.0.1 demo.local' | sudo tee -a /etc/hosts
  echo '127.0.0.1 second.local' | sudo tee -a /etc/hosts
fi
```
10. Access services:

| Service     | URL                                            |
| ----------- | ---------------------------------------------- |
| Nginx | http://demo.local:8080 |
| Second   | http://second.local:8080|

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

