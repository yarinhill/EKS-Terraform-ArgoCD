module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"
  cluster_name    = "${var.project_name}-cluster-${random_integer.eks_cluster_number.result}-${random_string.eks_cluster_string.result}"
  cluster_version = "1.32"
  create_iam_role = false
  kms_key_deletion_window_in_days = 7
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  cluster_security_group_use_name_prefix = false
  node_security_group_use_name_prefix = false
  enable_irsa = true
  iam_role_arn = aws_iam_role.eks-cluster.arn
  vpc_id =  module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets
  #cluster_endpoint_public_access_cidrs = var.your_public_ip
  cluster_endpoint_public_access_cidrs = flatten([
    var.your_public_ip,
    #"1.1.1.1/32"# Add IP for another instance
  ])
  cluster_security_group_additional_rules = {
    https_ingress_from_bastion = {
      description = "Allow HTTPS from Bastion to EKS API"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      source_security_group_id = aws_security_group.bastion-sg.id
      type        = "ingress"
    }
  }
  cluster_security_group_tags = {
    Name = "${var.project_name}-cluster-sg"
  }
  node_security_group_tags = {
    Name = "${var.project_name}-eks-node-sg"
  }
  cluster_addons = {
    coredns   = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }
  node_security_group_additional_rules = {
    ssh_ingress = {
      description = "Allow SSH from Bastion"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      source_security_group_id = aws_security_group.bastion-sg.id
      type        = "ingress"
    }
    argocd_lb_sg ={
      description = "Allow Incoming Ports from ArgoCD-LB"
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      source_security_group_id = aws_security_group.argocd_lb_sg.id
      type        = "ingress"
    }
    node_app_lb_sg ={
      description = "Allow Incoming Ports from Node-App-LB"
      from_port   = 30000
      to_port     = 32767
      protocol    = "tcp"
      source_security_group_id = aws_security_group.node_app_lb_sg.id
      type        = "ingress"
    }
  }
  eks_managed_node_groups = {
    "${var.project_name}-eks-node" = {
      create_iam_role = false
      override_name   = true
      subnet_ids = module.vpc.private_subnets
      name = "${var.project_name}-eks-node-group"
      launch_template_name = "${var.project_name}-eks-node-launch-template"
      node_group_autoscaling_group_names = "${var.project_name}-eks-node-autoscaling-group"
      key_name = aws_key_pair.master-key.key_name
      iam_role_arn = aws_iam_role.nodes.arn
      node_group_name = "eks-nodes"
      ami_type       = var.ami_type
      instance_types = var.node_instance_types
      capacity_type = "SPOT"
      min_size     = 2
      desired_size = 2
      max_size     = 4
    }
  }
  access_entries = {
    /*
    <your_user> = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::<account_id>:user/<your_user>"
      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
        cluster_admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    */
    bastion = {
      kubernetes_groups = []
      principal_arn     = aws_iam_role.bastion.arn
      policy_associations = {
        admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
        cluster_admin_policy = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }
  depends_on = [
    aws_iam_role_policy_attachment.amazon-eks-cluster-policy,
    aws_iam_role_policy_attachment.amazon-eks-service-policy,
    aws_iam_role_policy_attachment.custom_cluster_policy_attachment,
    aws_iam_role_policy_attachment.custom_node-group_policy_attachment,
    aws_iam_role_policy_attachment.amazon-eks-worker-node-policy,
    aws_iam_role_policy_attachment.amazon-eks-cni-policy,
    aws_iam_role_policy_attachment.amazon-ec2-container-registry-read-only
  ]
}

resource "aws_iam_role" "eks-cluster" {
  name = "${var.project_name}-eks-cluster-role"
  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "eks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY
}

resource "aws_iam_role" "nodes" {
  name = "${var.project_name}-node-group-role"
  assume_role_policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  POLICY
}

resource "aws_iam_policy" "custom_cluster_policy" {
  name        = "CustomPolicyForEKSCluster"
  description = "Custom policy for EKS Cluster"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCustomActions",
        Effect    = "Allow",
        Action    = [
          "eks:DescribeUpdate",
          "eks:UpdateClusterConfig"
        ],
        Resource  = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "custom_node-group_policy" {
  name        = "CustomPolicyForEKSNodes"
  description = "Custom policy for EKS nodes"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCustomActions",
        Effect    = "Allow",
        Action    = [
          "eks:DescribeAddon"
        ],
        Resource  = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "amazon-eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "amazon-eks-service-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "custom_cluster_policy_attachment" {
  policy_arn = aws_iam_policy.custom_cluster_policy.arn
  role       = aws_iam_role.eks-cluster.name
}

resource "aws_iam_role_policy_attachment" "custom_node-group_policy_attachment" {
  policy_arn = aws_iam_policy.custom_node-group_policy.arn
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "amazon-eks-worker-node-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "amazon-eks-cni-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "amazon-ec2-container-registry-read-only" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}
