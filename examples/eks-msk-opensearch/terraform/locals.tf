locals {
  resource_name_prefix = "${var.org}-${var.env}-${var.region_short}"

  cluster_name = "eks-${local.resource_name_prefix}"

  es_cluster_name = "es-${local.resource_name_prefix}"

  es_zone_awareness_enabled = length(data.aws_availability_zones.available.names) > 1

  # Used to determine correct partition (i.e. - `aws`, `aws-gov`, `aws-cn`, etc.)
  partition = data.aws_partition.current.partition

  tags = {
    terraform = "true"
    env       = "${var.env}"
  }
}
