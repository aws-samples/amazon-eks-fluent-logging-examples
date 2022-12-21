# https://github.com/gretelai/FluentBitLogging/blob/master/terraform/cluster/kubernetes/fluentbit.tf

resource "helm_release" "fluent_bit_daemonset" {
  namespace        = "logging"
  create_namespace = true
  cleanup_on_fail  = true

  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.20.6"

  values = [
    templatefile("${path.module}/templates/fluent-bit.yaml", {
      image_version        = "1.9.10",
      service_account_name = kubernetes_service_account.logging.metadata.0.name,
      kafka_brokers        = join(",", formatlist("%s", split(",", module.kafka.bootstrap_brokers))),
      namespaces           = join("|", [for namespace in var.namespaces : namespace.name if namespace.enable_logs_to_es])
    }),
  ]
}

resource "kubernetes_network_policy" "logging_network_policy" {
  metadata {
    name      = "logging-network-policy"
    namespace = "logging"
  }

  spec {
    policy_types = [
      "Ingress",
      "Egress"
    ]

    # Applies to all pods in the logging namespace.
    pod_selector {}

    # Block all Ingress with no rule.

    # Allow all Egress
    egress {}
  }

  depends_on = [
    module.kafka
  ]
}
