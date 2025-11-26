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
  name  = "demo-nginx"
  image = "nginx:latest"

  networks_advanced {
    name = docker_network.demo.name
  }

  ports {
    internal = 80
    external = 8080
  }
}

resource "docker_image" "postgres" {
  name = "postgres:16"
  keep_locally = false
}

resource "docker_volume" "postgres_data" {
  name = "postgres-data-demo"
}

resource "docker_container" "postgres" {
  name = "postgres-demo"
  image = docker_image.postgres.image_id

  networks_advanced {
    name = docker_network.demo.name
  }

  env = [
    "POSTGRES_USER=postgres",
    "POSTGRES_PASSWORD=postgres",
    "POSTGRES_DB=demo_db"
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
    context    = "${path.module}/notes-api"
  }

  keep_locally = false
}

resource "docker_container" "notes-api" {
  name  = "notes-api-demo"
  image = docker_image.notes-api.image_id

  networks_advanced {
    name = docker_network.demo.name
  }

  env = [
    "DB_HOST=${docker_container.postgres.name}",
    "DB_PORT=5432",
    "DB_USER=postgres",
    "DB_PASSWORD=postgres",
    "DB_NAME=demo_db"
  ]

  ports {
    internal = 3000
    external = 3000
  }

  depends_on = [docker_container.postgres]
}