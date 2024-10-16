terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.13.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.16.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  profile = var.profile
  region  = var.region
  alias   = "region-master"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  token                  = data.aws_eks_cluster_auth.cluster.token  # Token for authentication
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
      command     = "aws"
    }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token  # Token for authentication
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  }
}

#Available Zones
data "aws_availability_zones" "available" {
  state = "available"
}

#Bastion Start Script
data "template_file" "start_bastion_script" {
  template = file("${path.module}/user_data/start-bastion.sh")
  vars = {
    remote_user          = var.remote_user,
    region-master        = var.region,
    deploy-name          = var.project_name,
    private_key_file     = var.private_key_file,
  }
}

#Fetch EKS Cluster Authentication
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

#Create key-pair for logging into EC2 for Instance
resource "aws_key_pair" "master-key" {
  provider   = aws.region-master
  key_name   = var.project_name
  public_key = file(var.public_key_file)
}

#Random EKS Cluster Number
resource "random_integer" "eks_cluster_number" {
  min = 1000
  max = 9999
}

#Random EKS Cluster String
resource "random_string" "eks_cluster_string" {
  length  = 6
  upper   = false
  special = false
}

#Random Public Subnet Index 
resource "random_integer" "subnet_index" {
  min = 0
  max = length(module.vpc.public_subnets) - 1
}

#For ArgoCD DNS Record
data "kubernetes_service" "argocd_service" {
  metadata {
    name      = "argocd-server"  # Ensure this matches your service name in the ArgoCD chart
    namespace = "argocd"
  }
  depends_on = [helm_release.argocd]
}
