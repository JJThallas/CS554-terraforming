terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_network" "demo" {
  name = "demo-net"
}

resource "docker_container" "nginx" {
  name  = "nginx"
  image = "nginx:latest"

  networks_advanced {
    name = docker_network.demo.name
  }

  mounts {
    target = "/etc/nginx/conf.d/default.conf"
    source = abspath("${path.module}/nginx/default.conf")
    type = "bind"
  }

  ports {
    internal = 80
    external = 8080
  }

  depends_on = [docker_container.notes-api]
}

resource "docker_image" "postgres" {
  name = "postgres:16"
  keep_locally = false
}

resource "docker_volume" "postgres_data" {
  name = "postgres-data"
}

resource "docker_container" "postgres" {
  name = "postgres"
  image = docker_image.postgres.image_id

  networks_advanced {
    name = docker_network.demo.name
  }

  env = [
    "POSTGRES_USER=postgres",
    "POSTGRES_PASSWORD=postgres",
    "POSTGRES_DB=db"
  ]

  mounts {
    target = "/var/lib/postgresql/data"
    source = docker_volume.postgres_data.name
    type = "volume"
  }

  ports {
    internal = 5432
    external = 5432
  }
}

resource "docker_image" "notes-api" {

  name = "notes-api:latest"
  build {
    context = "${path.module}/backend"
  }

  keep_locally = false

  depends_on = [docker_container.postgres]
}

resource "docker_container" "notes-api" {
  name = "notes-api"
  image = docker_image.notes-api.image_id

  networks_advanced {
    name = docker_network.demo.name
  }

  env = [
    "DB_HOST=${docker_container.postgres.name}",
    "DB_PORT=5432",
    "DB_USER=postgres",
    "DB_PASSWORD=postgres",
    "DB_NAME=db"
  ]

  ports {
    internal = 3000
    external = 3000
  }

  depends_on = [docker_container.postgres]
}

resource "docker_volume" "prometheus_data" {
  name = "prometheus-data"
}

resource "docker_image" "prometheus" {
  name = "prom/prometheus:latest"
  keep_locally = false
}

resource "docker_container" "prometheus" {
  name = "prometheus"
  image = docker_image.prometheus.image_id

  networks_advanced {
    name = docker_network.demo.name
  }

  mounts {
    target = "/etc/prometheus/prometheus.yml"
    source = abspath("${path.module}/prometheus/prometheus.yml")
    type = "bind"
  }

  mounts {
    target = "/prometheus"
    source = docker_volume.prometheus_data.name
    type   = "volume"
  }


  ports {
    internal = 9090
    external = 9090
  }

  depends_on = [docker_container.notes-api]
}
