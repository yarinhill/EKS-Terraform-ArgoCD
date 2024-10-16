resource "aws_security_group" "node_app_lb_sg" {
  name        = "${var.project_name}-Node-app-lb-sg"
  description = "Security group for Node-App-LB"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = var.node_app_listen_port
    to_port     = var.node_app_listen_port
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
    Name = "${var.project_name}-node-app-lb-sg"
  }
}

