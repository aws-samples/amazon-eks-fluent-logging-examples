resource "aws_eip" "nat" {
  count = 1
  vpc   = true

  tags = merge(
    {
      "Name" = "nat-${local.resource_name_prefix}"
    },
    local.tags
  )
}


module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  create_vpc = true

  name = "vpc-${local.resource_name_prefix}"
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.available.names
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  # Single NAT Gateway
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_vpn_gateway   = true
  enable_dns_hostnames = true

  reuse_nat_ips       = true
  external_nat_ip_ids = aws_eip.nat.*.id


 # tags = merge(
 #   {
 #     "kubernetes.io/cluster/eks-${local.resource_name_prefix}" = "shared"
 #   },
 #   local.tags
 # )

  # https://aws.amazon.com/premiumsupport/knowledge-center/eks-vpc-subnet-discovery/
  public_subnet_tags = merge(
    {
      "kubernetes.io/cluster/eks-${local.resource_name_prefix}" = "shared"
      "kubernetes.io/role/elb"                                  = "1"
    },
    local.tags
  )


  private_subnet_tags = merge(
    {
      "kubernetes.io/cluster/eks-${local.resource_name_prefix}" = "shared"
      "kubernetes.io/role/internal-elb"                         = "1"
    },
    local.tags
  )
}
