#Create and bootstrap EC2 For bastion
resource "aws_instance" "bastion" {
  provider                    = aws.region-master
  ami                         = data.aws_ssm_parameter.linuxAmi.value
  instance_type               = var.bastion_instance_type
  key_name                    = aws_key_pair.master-key.key_name
  iam_instance_profile        = aws_iam_instance_profile.bastion.name
  vpc_security_group_ids      = [aws_security_group.bastion-sg.id]
  subnet_id = module.vpc.public_subnets[random_integer.subnet_index.result]
  associate_public_ip_address = true
  #Create a Spot Request for the instance
  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type  = "one-time"
      max_price = 0.010
    }
  }
  tags = {
    Name = "${var.project_name}-bastion"
  }
  connection {
    type        = "ssh"
    user        = var.remote_user
    private_key = file("${var.private_key_file}")
    host        = self.public_ip
  }
  provisioner "file" {
    source      = var.private_key_file
    destination = "/home/${var.remote_user}/.ssh/id_rsa"
  }
  user_data = data.template_file.start_bastion_script.rendered
  depends_on = [aws_security_group.bastion-sg]
}

#Create SG for Bastion, SSH only
resource "aws_security_group" "bastion-sg" {
  provider    = aws.region-master
  name        = "${var.project_name}-Bastion-sg"
  description = "Allow SSH"
  vpc_id      = module.vpc.vpc_id
  ingress {
    description = "Allow SSH from Your IP"
    from_port   = 22
    to_port     = 22
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
    Name = "${var.project_name}-bastion-sg"
  }
  depends_on = [module.vpc]
}

resource "aws_iam_role" "bastion" {
  name = "${var.project_name}-bastion-role"
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

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.project_name}-bastion-instance-profile"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_policy" "custom_bastion_policy" {
  name        = "CustomPolicyForBastionInstance"
  description = "Custom policy for Bastion Instance"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCustomActions",
        Effect    = "Allow",
        Action    = [
          "eks:ListClusters",
          "eks:DescribeCluster",
          "eks:ListNodegroups",
          "eks:DescribeNodegroup",
          "eks:DescribeClusterVersions",
          "ec2:DescribeInstances"
        ],
        Resource  = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_bastion_policy" {
  policy_arn = aws_iam_policy.custom_bastion_policy.arn
  role       = aws_iam_role.bastion.name
}
