provider "aws" {
  alias  = "this"
  region = var.region
}

terraform {
  backend "s3" {
    bucket = ""
    key = "eks-msk-opensearch/terraform.tfstate"
    region = "us-west-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.29"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.2.3"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.11.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.5.1"
    }

  }
}


provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.eks_auth.token
}


provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_id]
      command     = "aws"
    }
  }
}
