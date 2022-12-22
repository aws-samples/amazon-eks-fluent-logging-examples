################################################################################
# Service Account
################################################################################

resource "kubernetes_service_account" "logging" {
  metadata {
    name      = "logging"
    namespace = "logging"
    labels = {
      "app.kubernetes.io/managed-by" = "Helm"
      "app.kubernetes.io/instance"   = "fluent-bit"
      "app.kubernetes.io/name"       = "fluent-bit"
      "app.kubernetes.io/version"    = "1.9.7"
      "helm.sh/chart"                = "fluent-bit-0.20.6"
    }
    annotations = {
      "eks.amazonaws.com/role-arn"     = module.logging_irsa.iam_role_arn
      "meta.helm.sh/release-name"      = "fluent-bit"
      "meta.helm.sh/release-namespace" = "logging"
    }
  }
}
