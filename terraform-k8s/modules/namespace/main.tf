variable "name" {}

resource "kubernetes_namespace" "ns" {
  metadata {
    name = var.name
  }
}

output "name" {
  value = kubernetes_namespace.ns.metadata[0].name
}
