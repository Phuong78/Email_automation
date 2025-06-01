resource "aws_ebs_volume" "nfs_data_volume" {
  availability_zone = aws_subnet.private[0].availability_zone # Đặt EBS volume cùng AZ với NFS server
  size              = var.nfs_volume_size_gb
  type              = "gp3"
  tags = {
    Name    = "${var.project_name}-NFS-DataVolume"
    Project = var.project_name
  }
}

resource "aws_instance" "nfs_server" {
  ami                         = var.nfs_server_ami_id
  instance_type               = var.nfs_instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.private[0].id # Đặt NFS server ở private subnet
  vpc_security_group_ids      = [aws_security_group.nfs_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.nfs_profile.name
  # associate_public_ip_address = false # Không cần IP public vì truy cập nội bộ VPC

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y nfs-kernel-server xfsprogs util-linux # util-linux cho lsblk, blkid

              # Đợi một chút để EBS volume có thể được nhận diện
              sleep 15

              # Tìm device name cho EBS volume mới (ví dụ /dev/xvdf hoặc /dev/nvme1n1)
              # CẢNH BÁO: Cách xác định device name này cần được kiểm tra kỹ trên loại instance thực tế.
              # Nó giả định volume mới là device block thứ hai không phải là root (nvme0n1) và không phải là phân vùng (không có 'p' theo sau).
              EBS_DEVICE_NAME=$(lsblk -ndo NAME,TYPE | awk '$2=="disk" && $1 != "nvme0n1" {print "/dev/"$1; exit}')

              # Kiểm tra xem device đã có file system chưa và format nếu chưa
              if [ -n "$EBS_DEVICE_NAME" ] && ! sudo blkid -s TYPE -o value $EBS_DEVICE_NAME; then
                echo "Formatting $EBS_DEVICE_NAME with XFS..."
                sudo mkfs.xfs -f $EBS_DEVICE_NAME
              else
                echo "Device $EBS_DEVICE_NAME already has a filesystem or not found."
              fi
              
              sudo mkdir -p /srv/nfs_share
              
              # Lấy UUID của device để mount ổn định, chỉ thực hiện nếu device tồn tại
              if [ -n "$EBS_DEVICE_NAME" ] && sudo blkid -s UUID -o value $EBS_DEVICE_NAME; then
                EBS_UUID=$(sudo blkid -s UUID -o value $EBS_DEVICE_NAME)
                echo "UUID=$EBS_UUID  /srv/nfs_share  xfs  defaults,nofail  0  2" | sudo tee -a /etc/fstab
                sudo mount -a # Mount tất cả các entry trong fstab
              else
                echo "Could not reliably get UUID for $EBS_DEVICE_NAME. Manual mount might be needed."
              fi
              
              sudo chown nobody:nogroup /srv/nfs_share
              sudo chmod 777 /srv/nfs_share # Cân nhắc quyền chặt chẽ hơn cho production
              
              # Sử dụng VPC CIDR block cho phép truy cập từ toàn bộ VPC
              echo "/srv/nfs_share    ${var.vpc_cidr_block}(rw,sync,no_subtree_check,no_root_squash)" | sudo tee /etc/exports
              
              sudo exportfs -ar
              sudo systemctl restart nfs-kernel-server
              sudo systemctl enable nfs-kernel-server
              EOF

  tags = {
    Name    = "${var.project_name}-NFSServer"
    Project = var.project_name
    Role    = "NFS"
  }
}

resource "aws_volume_attachment" "nfs_data_volume_attach" {
  device_name = "/dev/sdf" # Hoặc /dev/xvdf. Tên này có thể thay đổi tùy loại instance và HĐH.
                           # Trên các instance Nitro (như T3), EBS volumes thường là /dev/nvmeXn1.
                           # Script user_data ở trên cố gắng tự phát hiện, nhưng tên này là để Terraform biết.
  volume_id   = aws_ebs_volume.nfs_data_volume.id
  instance_id = aws_instance.nfs_server.id
  # skip_destroy = true # Để giữ lại volume khi destroy instance, nếu cần
}