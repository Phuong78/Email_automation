output "vpc_id" {
  description = "ID của VPC chính."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Danh sách ID của các public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Danh sách ID của các private subnets."
  value       = aws_subnet.private[*].id
}

output "nagios_server_public_ip" {
  description = "Địa chỉ IP công cộng của Nagios Server."
  value       = aws_instance.nagios_server.public_ip
}

output "nagios_server_private_ip" {
  description = "Địa chỉ IP private của Nagios Server."
  value       = aws_instance.nagios_server.private_ip
}

output "nfs_server_private_ip" {
  description = "Địa chỉ IP private của NFS Server (dùng cho các client trong VPC)."
  value       = aws_instance.nfs_server.private_ip
}

output "nfs_server_export_path" {
  description = "Đường dẫn export trên NFS Server."
  value       = "/srv/nfs_share" # Hoặc giá trị bạn cấu hình trong user_data
}

output "customer_mail_server_iam_role_arn" {
  description = "ARN của IAM Role cho các máy chủ mail của khách hàng."
  value       = aws_iam_role.customer_mail_server_role.arn
}

output "customer_mail_server_instance_profile_name" {
  description = "Tên của IAM Instance Profile cho các máy chủ mail của khách hàng."
  value       = aws_iam_instance_profile.customer_mail_profile.name
}