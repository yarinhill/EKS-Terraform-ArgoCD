resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  force_update     = true
  create_namespace = true
  depends_on       = [helm_release.lb-controller]
  values = [
    templatefile("../helm/argocd/nlb.yaml", {
      SUBNET_IDS = join(",", module.vpc.public_subnets),
      ARGOCD_LB_SG_ID = aws_security_group.argocd_lb_sg.id
    })
  ]
}

resource "aws_security_group" "argocd_lb_sg" {
  name        = "${var.project_name}-argocd-lb-sg"
  description = "Security group for ArgoCD-LB"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.your_public_ip
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.your_public_ip
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.project_name}-argocd-lb-sg"
  }
}
