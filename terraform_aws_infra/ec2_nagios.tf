resource "aws_instance" "nagios_server" {
  ami                         = var.nagios_server_ami_id
  instance_type               = var.nagios_instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.public[0].id # Chạy Nagios ở public subnet đầu tiên
  vpc_security_group_ids      = [aws_security_group.nagios_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.nagios_profile.name
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y docker.io
              sudo systemctl enable docker --now
              sudo usermod -aG docker ubuntu # Thêm user ubuntu vào group docker

              # Đợi Docker khởi động hoàn toàn
              sleep 10 

              # Chạy lệnh docker với sudo nếu usermod chưa có hiệu lực ngay
              # Chuẩn bị thư mục cấu hình cho Nagios trên host
              mkdir -p /home/ubuntu/nagios_config/etc
              mkdir -p /home/ubuntu/nagios_config/var
              mkdir -p /home/ubuntu/nagios_config/custom-plugins
              # Cấp quyền cho user ubuntu (UID 1000)
              sudo chown -R ubuntu:ubuntu /home/ubuntu/nagios_config

              # Chạy Nagios container
              sudo docker run -d \
                --name nagios_server_container \
                -p 8081:80 \
                -v /home/ubuntu/nagios_config/etc:/opt/nagios/etc \
                -v /home/ubuntu/nagios_config/var:/opt/nagios/var \
                -v /home/ubuntu/nagios_config/custom-plugins:/opt/nagios/libexec/custom-plugins \
                --restart unless-stopped \
                jasonrivers/nagios:latest
              EOF

  tags = {
    Name    = "${var.project_name}-NagiosServer"
    Project = var.project_name
    Role    = "Nagios"
  }
}