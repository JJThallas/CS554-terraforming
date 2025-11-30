variable "namespace" {
  type = string
}

resource "kubernetes_deployment" "second" {
  metadata {
    name      = "second"
    namespace = var.namespace
    labels = {
      app = "second"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "second"
      }
    }

    template {
      metadata {
        labels = {
          app = "second"
        }
      }

      spec {
        container {
          name  = "second"
          image = "nginxdemos/hello:plain-text"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "second" {
  metadata {
    name      = "second"
    namespace = var.namespace
  }

  spec {
    selector = {
      app = kubernetes_deployment.second.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_ingress_v1" "second" {
  metadata {
    name      = "second"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }

  spec {
    rule {
      host = "second.local"

      http {
        path {
          path = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.second.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
