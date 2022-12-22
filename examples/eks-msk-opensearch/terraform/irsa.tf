################################################################################
# IRSA
################################################################################

module "logging_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.3.0"

  role_name = "logging-${local.resource_name_prefix}"

  oidc_providers = {
    ex = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "logging:logging"
      ]
    }
  }
  tags = local.tags
}
