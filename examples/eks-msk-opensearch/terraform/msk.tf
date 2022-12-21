module "kafka" {
  source  = "cloudposse/msk-apache-kafka-cluster/aws"
  version = "1.1.1"

  name                 = "kafka-${local.resource_name_prefix}"
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnets
  kafka_version        = var.kafka_version
  broker_per_zone      = 1
  broker_instance_type = var.broker_instance_type
  client_broker        = "PLAINTEXT"

  jmx_exporter_enabled  = true
  node_exporter_enabled = true

  additional_security_group_rules = [{
    type        = "ingress"
    protocol    = "all"
    from_port   = 0
    to_port     = 65535
    cidr_blocks = [var.vpc_cidr]
    description = "Allow traffic from vpc"
  }]

  properties = {
    "auto.create.topics.enable" : "true"
  }

  tags = local.tags

}


################################################################################
# MSK Connect
################################################################################

resource "aws_s3_bucket" "connectors" {
  bucket = "msk-connector-${local.resource_name_prefix}"
  tags   = local.tags
}

resource "aws_s3_bucket_acl" "connectors" {
  bucket = aws_s3_bucket.connectors.id
  acl    = "private"
}


resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.connectors.id

  # Block new public ACLs and uploading public objects
  block_public_acls = true

  # Retroactively remove public access granted through public ACLs
  ignore_public_acls = true

  # Block new public bucket policies
  block_public_policy = true

  # Retroactivley block public and cross-account access if bucket has public policies
  restrict_public_buckets = true
}


resource "aws_s3_object" "kafka-connect-opensearch" {
  # https://github.com/aiven/opensearch-connector-for-apache-kafka
  bucket = aws_s3_bucket.connectors.id
  key    = "opensearch-connector-for-apache-kafka-2.0.1"
  source = "connectors/opensearch-connector-for-apache-kafka-2.0.1.zip"
}


resource "aws_mskconnect_custom_plugin" "kafka-connect-opensearch-plugin" {
  name         = "kafka-connect-opensearch-plugin-${local.resource_name_prefix}"
  content_type = "ZIP"
  location {
    s3 {
      bucket_arn = aws_s3_bucket.connectors.arn
      file_key   = aws_s3_object.kafka-connect-opensearch.key
    }
  }
}


resource "aws_iam_role" "msk-connector-role" {
  name = "msk-connector-role-${local.resource_name_prefix}"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "kafkaconnect.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" : data.aws_caller_identity.current.account_id
          }
          ArnLike = {
            "aws:SourceArn" : module.kafka.cluster_arn
          }
        }
      },
    ]
  })

  tags = local.tags
}



resource "aws_mskconnect_connector" "kafka-connect-fluentbit" {
  name = "kafka-connect-fluentbit-${local.resource_name_prefix}"

  kafkaconnect_version = "2.7.1"

  capacity {
    autoscaling {
      mcu_count        = 1
      min_worker_count = 1
      max_worker_count = 4

      scale_in_policy {
        cpu_utilization_percentage = 20
      }

      scale_out_policy {
        cpu_utilization_percentage = 80
      }
    }
  }

  # https://docs.confluent.io/platform/7.2.1/connect/references/allconfigs.html
  connector_configuration = {
    "connector.class"                = "io.aiven.kafka.connect.opensearch.OpensearchSinkConnector"
    "key.converter"                  = "org.apache.kafka.connect.storage.StringConverter"
    "value.converter"                = "org.apache.kafka.connect.json.JsonConverter"
    "name"                           = "kafka-connect-fluentbit-${local.resource_name_prefix}"
    "type.name"                      = "kafka-connect"
    "tasks.max"                      = "1"
    "topics"                         = join(",", [for namespace in var.namespaces : "logs_${namespace.name}" if namespace.enable_logs_to_es])
    "connection.url"                 = "https://${aws_opensearch_domain.opensearch.endpoint}"
    "connection.username"            = var.es_master_user_name
    "connection.password"            = var.es_master_user_password
    "key.ignore"                     = "true"
    "schema.ignore"                  = "true"
    "compact.map.entries"            = "false"
    "behavior.on.null.values"        = "delete"
    "behavior.on.version.conflict"   = "ignore"
    "value.converter.schemas.enable" = "false"
    "errors.tolerance"               = "all"
  }

  kafka_cluster {
    apache_kafka_cluster {
      bootstrap_servers =  module.kafka.bootstrap_brokers
      vpc {
        security_groups = [module.kafka.security_group_id]
        subnets         = module.vpc.private_subnets
      }
    }
  }

  kafka_cluster_client_authentication {
    authentication_type = "NONE"
  }

  kafka_cluster_encryption_in_transit {
    encryption_type = "PLAINTEXT"
  }

  plugin {
    custom_plugin {
      arn      = aws_mskconnect_custom_plugin.kafka-connect-opensearch-plugin.arn
      revision = aws_mskconnect_custom_plugin.kafka-connect-opensearch-plugin.latest_revision
    }
  }

  #  log_delivery {
  #    worker_log_delivery {
  #      s3 {
  #        enabled = true
  #        bucket  = ""
  #        prefix  = "logs"
  #      }
  #    }
  #  }

  service_execution_role_arn = aws_iam_role.msk-connector-role.arn

  depends_on = [
    module.kafka
  ]
}
