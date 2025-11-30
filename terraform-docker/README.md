# Terraforming with Docker

This directory contains all of the Terraform and Docker files for my submission to Project 2 - Terraform. The full stack includes:

- A PostgreSQL database
- A custom Notes API backend
- An NGINX reverse proxy
- A dedicated Docker network connecting all services
- Volumes for data persistence

For my enhancement, I have added:

- Prometheus for metrics collection
- Grafana for metrics visualization

Terraform manages the creation, networking, configuration, and orchestration of all containers.

## Quick Start

1. Install Docker ([Docker Desktop](https://docs.docker.com/desktop/setup/install/windows-install/) for Windows, [Docker Engine](https://docs.docker.com/engine/install/) for Linux) and [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).
2. Initialize terraform:
```
terraform init
```
3. Apply terraform:
```
terraform apply
```
4. Access services:

| Service     | URL                                            |
| ----------- | ---------------------------------------------- |
| NGINX Proxy | http://localhost:8080 |
| Notes API   | http://localhost:8080/notes|
| Prometheus  | http://localhost:8080/metrics |
| Grafana     | http://localhost:3001 |


## Directory Overview

### /backend
Contains everything necessary to build the notes-api docker image, including a Dockerfile and source code in Python.

### /nginx
Contains the configuration to set up a nginx reverse proxy to host the API on localhost:8080.

### prometheus
Contains monitoring configurations for the prometheus image.

## Terraform Overview (main.tf resources)

### Docker Provider
Terraform requires a Docker provider to do Docker things.
```hcl
required_providers {
  docker = {
    source  = "kreuzwerker/docker"
    version = "~> 3.0"
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}
```
This installs the necessary plugin.

### Docker Network
The stack uses a custom, isolated Docker netowrk "demo-net":
```hcl
resource "docker_network" "demo" {
  name = "demo-net"
}
```
All containers use this network.

### Postgres DB
`docker_image.postgres` - Built from [Postgres](https://hub.docker.com/_/postgres) 16.

`docker_volume.postgres_data` -
Provides persistent storage to the DB.

`docker_container.postgres` -
Runs PostgreSQL with secret variables stored in terraform.tfvars. Exposed to port 5432.

### Notes-API
`docker_image.notes-api` - Custom API image built from the `/backend` directory.

`docker_container.notes-api` - Runs the API container with secret variables to connect to Postgres. Exposed to port 3000.

### Nginx Reverse Proxy
`docker_image.nginx` - Latest [nginx image](https://hub.docker.com/_/nginx).

`docker_contianer.nginx` - Runs Nginx with configurations from `default.conf`, then exposes 8080 -> 80 inside the container (reverse proxy).

### Prometheus Monitoring
Part of my enhancement to the project.

`docker_image.prometheus` - Latest [Prometheus image](https://hub.docker.com/r/prom/prometheus).

`docker_volume.prometheus_data` - Persistent volume to store metric data.

`docker_container.prometheus` - Runs Prometheus with persistent volume and config `prometheus.yml`. Exposed on port 9090.

### Grafana Visualization
Also part of my enhancement to the project. Creates visualizations of the metrics collected by Prometheus.

`docker_image.grafana` - Latest [Grafana image](https://hub.docker.com/r/grafana/grafana).

`docker_volume.grafana_data` - Persistent volume to store dashboard settings.

`docker_container.grafana` - Runs Grafana with persistent storage. Exposes 3001, container port 3000.


