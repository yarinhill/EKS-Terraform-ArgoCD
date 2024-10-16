
output "EKS_Cluster_Name" {
  description = "Kubernetes Cluster Name: "
  value       = module.eks.cluster_name
}

output "Command-to-Connect-to-the-EKS-Cluster" {
  description = "Run the following command to configure kubectl to work with your Amazon EKS cluster: "
  value       = "eksctl utils write-kubeconfig --cluster=${module.eks.cluster_name}"
}

output "Bastion_Public_IP" {
  description = "Bastion Public IP: "
  value       = aws_instance.bastion.public_ip
}

output "Command-to-Connect-to-the-Bastion-Instance" {
  description = "Run the following command to SSH into the Bastion Instance: "
  value       = "ssh -i ${var.private_key_file} ${var.remote_user}@${aws_instance.bastion.public_ip}"
}

output "Command-to-Get-ArgoCD-Admin-Password" {
  description = "Command to get the ArgoCD Admin Password:"
  value       = "kubectl -n argocd get secret argocd-initial-admin-secret -o json | jq -r '.data.password' | base64 --decode; echo"
}

output "AWS_REGION" {
  description = "AWS_REGION: "
  value       = var.region
}

output "ECR_REGISTRY_URL" {
  description = "The URL of the ECR repository: "
  value       = aws_ecr_repository.repo.repository_url
}

output "ARGOCD_LB_DNS" {
  description = "The DNS name of the ArgoCD Load Balancer"
  value = data.kubernetes_service.argocd_service.status[0].load_balancer[0].ingress[0].hostname
}

output "NODE_APP_SG_ID" {
  description = "The ID of the Node-App Security Group: "
  value       = aws_security_group.node_app_lb_sg.id
}

output "PUBLIC_SUBNETS_ID" {
  description = "The IDs of the Public Subnets:"
  value       = join(",", module.vpc.public_subnets)
}
