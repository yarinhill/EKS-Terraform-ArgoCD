module "lb_role" {
 source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
 role_name                              = "${var.project_name}-lb-role"
 attach_load_balancer_controller_policy = true
 oidc_providers = {
     main = {
     provider_arn               = module.eks.oidc_provider_arn
     namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

resource "kubernetes_service_account" "service-account" {
 metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    labels = {
     "app.kubernetes.io/name"      = "aws-load-balancer-controller"
     "app.kubernetes.io/component" = "controller"
    }
    annotations = {
     "eks.amazonaws.com/role-arn"               = module.lb_role.iam_role_arn
     "eks.amazonaws.com/sts-regional-endpoints" = "true"
    }
  }
  automount_service_account_token = true
  depends_on = [module.eks]
}

resource "helm_release" "lb-controller" {
 name       = "aws-load-balancer-controller"
 repository = "https://aws.github.io/eks-charts"
 chart      = "aws-load-balancer-controller"
 namespace  = "kube-system"
 depends_on = [
    kubernetes_service_account.service-account,
    module.eks
  ]
 set {
     name  = "region"
     value = var.region
  }
 set {
     name  = "vpcId"
     value = module.vpc.vpc_id
  }
 set {
    name  = "image.repository"
    value = "602401143452.dkr.ecr.${var.region}.amazonaws.com/amazon/aws-load-balancer-controller"
  }
 set {
     name  = "serviceAccount.create"
     value = "false"
  }  
 set {
     name  = "serviceAccount.name"
     value = "aws-load-balancer-controller"
  }
 set {
     name  = "clusterName"
     value = module.eks.cluster_name
  }
}

resource "aws_iam_policy" "lb_controller_policy" {
  name        = "${var.project_name}-lb-controller-policy"
  description = "CustomPolicyForLBController"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerAttributes",
          "elasticloadbalancing:CreateListener",
          "elasticloadbalancing:CreateLoadBalancer",
          "elasticloadbalancing:DeleteListener",
          "elasticloadbalancing:DeleteLoadBalancer",
          "elasticloadbalancing:ModifyListener"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_lb_controller_policy" {
  policy_arn = aws_iam_policy.lb_controller_policy.arn
  role       = module.lb_role.iam_role_name
}