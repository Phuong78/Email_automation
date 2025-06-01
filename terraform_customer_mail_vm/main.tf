provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "customer_vm_sg" {
  name        = "${var.project_name_tag}-${var.customer_name}-MailVM-SG" # Đảm bảo tên duy nhất và tuân thủ quy tắc
  description = "Security group for customer mail VM ${var.customer_name}" # Chỉ dùng ký tự ASCII
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # CẢNH BÁO: Mở SSH ra toàn thế giới. Nên giới hạn IP nguồn!
  }
  ingress {
    description = "SMTP (port 25)"
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Cho phép từ mọi nơi
  }
  ingress {
    description = "SMTPS / Submission (port 587)"
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "IMAPS (port 993)"
    from_port   = 993
    to_port     = 993
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "POP3S (port 995)"
    from_port   = 995
    to_port     = 995
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description      = "NRPE from Nagios Server"
    from_port        = 5666
    to_port          = 5666
    protocol         = "tcp"
    cidr_blocks      = ["${var.nagios_server_private_ip}/32"] # Chỉ cho phép từ IP private của Nagios Server
  }
  // Bạn có thể thêm các port khác nếu cần (ví dụ: HTTP/HTTPS cho webmail)

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Cho phép mọi traffic ra
  }

  tags = {
    Name     = "${var.project_name_tag}-${var.customer_name}-MailVM-SG"
    Project  = var.project_name_tag
    Customer = var.customer_name
  }
}

resource "aws_instance" "customer_vm" {
  ami                         = var.customer_vm_ami_id
  instance_type               = var.customer_vm_instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.customer_vm_sg.id]
  iam_instance_profile        = var.customer_mail_server_instance_profile_name
  associate_public_ip_address = true // Cần IP Public để Ansible kết nối từ Jenkins local

  # user_data để cài các gói cơ bản cần thiết trước khi Ansible chạy
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y python3 python3-pip nfs-common # python3 và pip cần cho một số module Ansible, nfs-common để mount NFS
              sudo mkdir -p /mnt/mail_data_share # Thư mục mount point cho NFS data
              EOF

  tags = {
    Name     = "${var.project_name_tag}-${var.customer_name}-MailVM"
    Project  = var.project_name_tag
    Customer = var.customer_name
  }
}