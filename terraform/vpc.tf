module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.15.0"
  name    = "${var.project_name}-vpc"
  cidr    = var.vpc_cidr
  azs     = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets  = var.private_subnets
  public_subnets   = var.public_subnets
  enable_nat_gateway   = true
  enable_dns_support   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "owned"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${var.project_name}-eks-cluster" = "owned"
  }
  public_route_table_tags = {
    "Name" = "${var.project_name}-public-route-table"
  }
  private_route_table_tags = {
    "Name" = "${var.project_name}-private-route-table"
  }
  igw_tags = {
    "Name" = "${var.project_name}-igw"
  }
  nat_gateway_tags = {
    "Name" = "${var.project_name}-nat-gateway"
  }
  nat_eip_tags = {
    "Name" = "${var.project_name}-nat-eip"
  }
}
