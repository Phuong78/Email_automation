# --- Security Group cho Nagios Server ---
resource "aws_security_group" "nagios_sg" {
  name        = "${var.project_name}-Nagios-SG"
  description = "SG for Nagios Server (ASCII only description)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.user_access_cidr]
  }
  ingress {
    description = "Nagios UI (port 8081)"
    from_port   = 8081 # Port bạn map cho Nagios UI trong user_data
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = [local.user_access_cidr]
  }
  ingress {
    description      = "NRPE from Customer VMs"
    from_port        = 5666
    to_port          = 5666
    protocol         = "tcp"
    cidr_blocks      = concat(var.public_subnet_cidrs, var.private_subnet_cidrs) # Cho phép từ các subnet trong VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-Nagios-SG"
  }
}

# --- Security Group cho NFS Server ---
resource "aws_security_group" "nfs_sg" {
  name        = "${var.project_name}-NFS-SG"
  description = "SG for NFS Server (ASCII only description)"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.user_access_cidr]
  }
  ingress {
    description = "NFS from within VPC (TCP)"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block] # Cho phép từ toàn bộ VPC
  }
  ingress {
    description = "NFS (UDP) from within VPC" # Một số client/phiên bản NFS cần UDP
    from_port   = 2049
    to_port     = 2049
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  ingress {
    description = "RPCbind/Portmapper (TCP) from within VPC"
    from_port   = 111
    to_port     = 111
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }
  ingress {
    description = "RPCbind/Portmapper (UDP) from within VPC"
    from_port   = 111
    to_port     = 111
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-NFS-SG"
  }
}