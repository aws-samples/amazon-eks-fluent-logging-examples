################################################################################
# AWS Load Balancer Controller
################################################################################

locals {
  namespace      = lookup(var.helm, "namespace", "kube-system")
  serviceaccount = lookup(var.helm, "serviceaccount", "aws-load-balancer-controller")
  lbc_tags = merge({
    "clusterName"                                               = module.eks.cluster_id
    "serviceAccount.name"                                       = local.serviceaccount
    "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = module.load_balancer_controller_irsa_role.iam_role_arn
  }, lookup(var.helm, "vars", {}))
}


resource "helm_release" "lbc" {
  name            = lookup(var.helm, "name", "aws-load-balancer-controller")
  chart           = lookup(var.helm, "chart", "aws-load-balancer-controller")
  version         = lookup(var.helm, "version", null)
  repository      = lookup(var.helm, "repository", "https://aws.github.io/eks-charts")
  namespace       = local.namespace
  cleanup_on_fail = lookup(var.helm, "cleanup_on_fail", true)

  dynamic "set" {
    for_each = local.lbc_tags
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    module.load_balancer_controller_irsa_role
  ]
}
