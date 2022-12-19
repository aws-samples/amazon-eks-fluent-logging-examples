// aws specific configurations
variable "region" {
  description = "AWS Region Name"
  default     = "us-west-1"
}

// Refer col A1 on
// https://gist.github.com/colinvh/14e4b7fb6b66c29f79d3
variable "region_short" {
  description = "AWS Region Name Short"
  default     = "uwe1"
}

variable "env" {
  description = "Environment Name"
  default     = "dev"
}

variable "org" {
  description = "Organization Name"
  default     = "example"
}

variable "vpc_cidr" {
  description = "CIDR range for vpc"
  default     = "10.1.0.0/16"
}

variable "vpc_private_subnets" {
  description = "Private subnet cidr"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "vpc_public_subnets" {
  description = "Public subnet cidr"
  type        = list(string)
  default     = ["10.1.101.0/24", "10.1.102.0/24"]
}


variable "eks_cluster_version" {
  description = "value of EKS Cluster Version"
  default     = "1.23"
}


variable "eks_node_instance_types" {
  description = "Instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium", "t3.large"]
}

variable "eks_node_disk_size" {
  description = "Disk size for EKS nodes"
  default     = "20"
}

variable "eks_node_group_min_size" {
  description = "Minimum size for EKS node group"
  default     = "1"
}

variable "eks_node_group_max_size" {
  description = "Maximum size for EKS node group"
  default     = "3"
}

variable "eks_node_group_desired_size" {
  description = "Desired size for EKS node group"
  default     = "1"
}



################################################################################
# HELM
################################################################################

variable "helm" {
  description = "The helm release configuration"
  type        = any
  default = {
    repository      = "https://aws.github.io/eks-charts"
    name            = "aws-load-balancer-controller"
    chart           = "aws-load-balancer-controller"
    namespace       = "kube-system"
    serviceaccount  = "aws-load-balancer-controller"
    cleanup_on_fail = true
    vars            = {}
  }
}

variable "namespaces" {
  description = "K8s namespaces to create"
  type = list(object({
    name              = string
    enable_logs_to_es = bool
  }))
  default = [
    {
      "name" : "logging",
      "enable_logs_to_es" = false,
    },
    {
      "name" : "example",
      "enable_logs_to_es" = true,
    }
  ]
}


variable "aws_auth_users" {
  description = "AWS auth users"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}



################################################################################
# Kafka Configuration
################################################################################


variable "kafka_version" {
  # https://docs.aws.amazon.com/msk/latest/developerguide/supported-kafka-versions.html
  description = "The desired Kafka software version"
  type        = string
  default     = "2.6.2"
}

variable "broker_instance_type" {
  # https://docs.aws.amazon.com/msk/latest/developerguide/bestpractices.html#bestpractices-right-size-cluster
  description = "The instance type to use for the Kafka brokers	"
  type        = string
  default     = "kafka.t3.small"
}

variable "broker_volume_size" {
  description = "The size in GiB of the EBS volume for the data drive on each broker node"
  type        = number
  default     = 100
}


################################################################################
# Opensearch Configuration
################################################################################
variable "es_cluster_version" {
  description = "The version of OpenSearch to deploy."
  type        = string
  default     = "1.3"
}

variable "es_master_user_name" {
  description = "Master username for Opensearch cluster"
  default     = "master"
}

variable "es_master_user_password" {
  description = "Master username for Opensearch cluster"
  sensitive   = true
}

variable "master_instance_enabled" {
  description = "Indicates whether dedicated master nodes are enabled for the cluster."
  type        = bool
  default     = true
}

variable "master_instance_type" {
  description = "The type of EC2 instances to run for each master node. A list of available instance types can you find at https://aws.amazon.com/en/opensearch-service/pricing/#On-Demand_instance_pricing"
  type        = string
  default     = "r6gd.large.search"

  validation {
    condition     = can(regex("^[m3|r3|i3|i2|r6gd]", var.master_instance_type))
    error_message = "The EC2 master_instance_type must provide a SSD or NVMe-based local storage."
  }
}

variable "master_instance_count" {
  description = "The number of dedicated master nodes in the cluster."
  type        = number
  default     = 3
}

variable "es_instance_count_multiplier" {
  description = "This number is multiplied by availability zone count to get instance count."
  type        = number
  default     = 1
}

variable "es_instance_type" {
  description = "The type of EC2 instances to run for each hot node. A list of available instance types can you find at https://aws.amazon.com/en/opensearch-service/pricing/#On-Demand_instance_pricing"
  type        = string
  default     = "r6gd.large.search"

  validation {
    condition     = can(regex("^[m3|r3|i3|i2|r6gd]", var.es_instance_type))
    error_message = "The EC2 hot_instance_type must provide a SSD or NVMe-based local storage."
  }
}

variable "warm_instance_enabled" {
  description = "Indicates whether ultrawarm nodes are enabled for the cluster."
  type        = bool
  default     = false
}

variable "warm_instance_type" {
  description = "The type of EC2 instances to run for each warm node. A list of available instance types can you find at https://aws.amazon.com/en/elasticsearch-service/pricing/#UltraWarm_pricing"
  type        = string
  default     = "ultrawarm1.large.search"
}

variable "warm_instance_count" {
  description = "The number of dedicated warm nodes in the cluster."
  type        = number
  default     = 2
}
