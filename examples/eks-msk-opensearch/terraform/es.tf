resource "aws_security_group" "es" {
  name        = "es-${local.resource_name_prefix}"
  description = "VPC only access to Elasticsearch"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = [
      var.vpc_cidr,
      "0.0.0.0/0"
    ]
  }
}



resource "aws_opensearch_domain" "opensearch" {
  domain_name     = local.es_cluster_name
  engine_version  = "OpenSearch_${var.es_cluster_version}"
  access_policies = data.aws_iam_policy_document.es_access_policy.json

  cluster_config {
    dedicated_master_enabled = var.master_instance_enabled
    dedicated_master_count   = var.master_instance_enabled ? var.master_instance_count : null
    dedicated_master_type    = var.master_instance_enabled ? var.master_instance_type : null

    instance_count = var.es_instance_count_multiplier * length(data.aws_availability_zones.available.names)
    instance_type  = var.es_instance_type

    warm_enabled = var.warm_instance_enabled
    warm_count   = var.warm_instance_enabled ? var.warm_instance_count : null
    warm_type    = var.warm_instance_enabled ? var.warm_instance_type : null

    zone_awareness_enabled = local.es_zone_awareness_enabled ? true : false
    dynamic "zone_awareness_config" {
      for_each = local.es_zone_awareness_enabled ? [length(data.aws_availability_zones.available.names)] : []
      content {
# fixing to 2 instead of 3 or more it expect max 3.
	   availability_zone_count = 2
      }
    }
  }

  vpc_options {
    subnet_ids         = module.vpc.public_subnets
    security_group_ids = [aws_security_group.es.id]
  }

  advanced_options = {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true

    master_user_options {
      # master_user_arn = data.aws_caller_identity.current.arn
      master_user_name     = var.es_master_user_name
      master_user_password = var.es_master_user_password
    }
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  node_to_node_encryption {
    enabled = true
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = aws_kms_key.eks.arn
  }

  tags = merge(
    {
      "Name" = local.es_cluster_name
    },
    local.tags
  )
}
