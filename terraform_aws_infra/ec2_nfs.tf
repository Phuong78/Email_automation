resource "aws_ebs_volume" "nfs_data_volume" {
  availability_zone = data.aws_availability_zones.available.names[0]
  size              = var.nfs_volume_size_gb
  type              = "gp3"
  tags = {
    Name    = "${var.project_name}-NFS-DataVolume"
    Project = var.project_name
  }
}

resource "aws_instance" "nfs_server" {
  ami                    = var.nfs_server_ami_id
  instance_type          = var.nfs_instance_type
  key_name               = var.key_pair_name
  subnet_id              = length(aws_subnet.private) > 0 ? aws_subnet.private[0].id : aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.nfs_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.nfs_profile.name

  # SỬ DỤNG HÀM file() ĐỂ ĐỌC NỘI DUNG TỪ FILE SCRIPT RIÊNG
  user_data = file("${path.module}/nfs_user_data.sh") # <---- THAY ĐỔI Ở ĐÂY

  tags = {
    Name    = "${var.project_name}-NFSServer"
    Project = var.project_name
    Role    = "NFS"
  }
}

resource "aws_volume_attachment" "nfs_data_volume_attach" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.nfs_data_volume.id
  instance_id = aws_instance.nfs_server.id
}