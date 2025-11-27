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