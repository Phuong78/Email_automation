variable "aws_region" {
  description = "Vùng AWS để triển khai máy chủ khách hàng."
  type        = string
}

variable "customer_name" {
  description = "Tên định danh của khách hàng."
  type        = string
}

variable "customer_vm_ami_id" {
  description = "AMI ID cho máy chủ mail của khách hàng."
  type        = string
}

variable "customer_vm_instance_type" {
  description = "Loại EC2 instance cho máy chủ mail của khách hàng."
  type        = string
}

variable "key_pair_name" {
  description = "Tên Key Pair trên AWS để truy cập máy chủ khách hàng."
  type        = string
}

variable "project_name_tag" {
  description = "Giá trị cho tag 'Project' trên tài nguyên của khách hàng."
  type        = string
}

variable "subnet_id" {
  description = "ID của Public Subnet nơi máy chủ khách hàng sẽ được tạo."
  type        = string
}

variable "vpc_id" {
  description = "ID của VPC chứa subnet (cần cho Security Group)."
  type        = string
}

variable "customer_mail_server_instance_profile_name" {
  description = "Tên của IAM Instance Profile sẽ gán cho máy chủ khách hàng."
  type        = string
}

variable "nagios_server_private_ip" {
  description = "IP Private của Nagios Server (để cấu hình rule NRPE trong Security Group)."
  type        = string
}