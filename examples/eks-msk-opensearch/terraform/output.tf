################################################################################
# VPC
################################################################################

output "vpc_name" {
  description = "VPC Name"
  value       = module.vpc.name
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "VPC Private Subnets"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "VPC Public Subnets"
  value       = module.vpc.public_subnets
}

################################################################################
# Cluster
################################################################################

output "cluster_arn" {
  description = "The Amazon Resource Name (ARN) of the cluster"
  value       = module.eks.cluster_arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_endpoint" {
  description = "Endpoint for your Kubernetes API server"
  value       = module.eks.cluster_endpoint
}

output "cluster_id" {
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = module.eks.cluster_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_oidc_provider_arn" {
  description = "OIDC provider arn"
  value       = module.eks.oidc_provider_arn
}

output "cluster_platform_version" {
  description = "Platform version for the cluster"
  value       = module.eks.cluster_platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster. One of `CREATING`, `ACTIVE`, `DELETING`, `FAILED`"
  value       = module.eks.cluster_status
}

output "cluster_primary_security_group_id" {
  description = "Cluster security group that was created by Amazon EKS for the cluster. Managed node groups use this security group for control-plane-to-data-plane communication. Referred to as 'Cluster security group' in the EKS console"
  value       = module.eks.cluster_primary_security_group_id
}


output "region" {
  description = "AWS region"
  value       = var.region
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = "eks-${local.resource_name_prefix}"
}

output "cluster_security_group_id" {
  description = "Cluster Security Group ID"
  value       = module.eks.cluster_security_group_id
}



################################################################################
# Kafka
################################################################################

output "kafka_cluster_arn" {
  description = "Amazon Resource Name (ARN) of the MSK cluster"
  value       = module.kafka.cluster_arn
}

output "kafka_config_arn" {
  description = "Amazon Resource Name (ARN) of the MSK configuration"
  value       = module.kafka.config_arn
}

output "kafka_hostname" {
  description = "DNS hostname of MSK cluster"
  value       = module.kafka.hostname
}

output "kafka_security_group_id" {
  description = "The ID of the security group rule for the MSK cluster"
  value       = module.kafka.security_group_id
}

output "kafka_security_group_name" {
  description = "The name of the security group rule for the MSK cluster"
  value       = module.kafka.security_group_name
}

output "kafka_cluster_name" {
  description = "The cluster name of the MSK cluster"
  value       = module.kafka.cluster_name
}

output "hostname" {
  description = "Comma separated list of one or more MSK Cluster Broker DNS hostname"
  value       = module.kafka.hostname
}


################################################################################
# MSK Connector
################################################################################

output "kafka_connect_arn" {
  description = "Amazon Resource Name (ARN) of the MSK Connect"
  value       = aws_mskconnect_connector.kafka-connect-fluentbit.arn
}


################################################################################
# Elasticsearch
################################################################################

output "es_cluster_name" {
  description = "The name of the OpenSearch cluster."
  value       = aws_opensearch_domain.opensearch.domain_name
}

output "es_cluster_version" {
  description = "The version of the OpenSearch cluster."
  value       = replace(aws_opensearch_domain.opensearch.engine_version, "OpenSearch_", "")
}

output "es_cluster_endpoint" {
  description = "The endpoint URL of the OpenSearch cluster."
  value       = "https://${aws_opensearch_domain.opensearch.endpoint}"
}



################################################################################
# Additional
################################################################################

output "aws_auth_configmap_yaml" {
  description = "Formatted yaml output for base aws-auth configmap containing roles used in cluster node groups/fargate profiles"
  value       = module.eks.aws_auth_configmap_yaml
}
