variable "namespace" {
  type = string
}

resource "kubernetes_deployment" "nginx" {
  metadata {
	name = "nginx-deployment"
	namespace = var.namespace
	labels = {
	  app = "demo-nginx"
	}
  }

  spec {
	replicas = 1

	selector {
	  match_labels = {
		app = "demo-nginx"
	  }
	}

	template {
	  metadata {
		labels = {
		  app = "demo-nginx"
		}
	  }

	  spec {
		container {
		  name  = "nginx"
		  image = "nginx:1.14.2"

		  port {
			container_port = 80
		  }
		}
	  }
	}
  }
}

resource "kubernetes_service" "nginx" {

  metadata {
	name = "demo-nginx"
	namespace = var.namespace
  }

  spec {
	selector = {
	  app = "demo-nginx"
	}

	port {
	  port        = 80
	  target_port = 80
	}

	type = "ClusterIP"
  }
}

output "deployment_name" {
  value = kubernetes_deployment.nginx.metadata[0].name
}

output "service_name" {
  value = kubernetes_service.nginx.metadata[0].name
}

resource "kubernetes_ingress_v1" "nginx" {
  metadata {
    name      = "demo-nginx-ingress"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class" = "traefik"
    }
  }

  spec {
    ingress_class_name = "traefik"

    rule {
      host = "demo.local"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = kubernetes_service.nginx.metadata[0].name
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

