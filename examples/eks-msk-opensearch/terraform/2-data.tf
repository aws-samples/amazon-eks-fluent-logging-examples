data "aws_eks_cluster_auth" "eks_auth" {
  name = module.eks.cluster_id
}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_iam_policy_document" "es_access_policy" {
  statement {
    actions   = ["es:*"]
    resources = ["arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.es_cluster_name}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
