resource "kubernetes_namespace" "eks_namespace" {
  for_each = { for i, v in var.namespaces : i => v }
  metadata {
    annotations = {
      name = var.namespaces[each.key].name
    }
    name = var.namespaces[each.key].name
  }
}
