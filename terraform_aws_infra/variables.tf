variable "aws_region" {
  description = "Vùng AWS để triển khai tài nguyên."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Tên dự án, sử dụng để gắn thẻ tài nguyên."
  type        = string
  default     = "EmailInfraProd"
}

variable "vpc_cidr_block" {
  description = "Dải CIDR cho VPC."
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Danh sách các dải CIDR cho public subnets."
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Danh sách các dải CIDR cho private subnets."
  type        = list(string)
  default     = ["10.10.101.0/24", "10.10.102.0/24"]
}

variable "nagios_instance_type" {
  description = "Loại EC2 instance cho Nagios server."
  type        = string
  default     = "t3.micro"
}

variable "nagios_server_ami_id" {
  description = "AMI ID Ubuntu Server 22.04 LTS gốc cho Nagios server."
  type        = string
  // QUAN TRỌNG: Lấy AMI ID mới nhất cho Ubuntu 22.04 LTS tại vùng var.aws_region
  // Ví dụ cho us-east-1 (amd64):
  default     = "ami-053b0d53c279acc90" // CẦN KIỂM TRA LẠI!
}

variable "nfs_instance_type" {
  description = "Loại EC2 instance cho NFS server."
  type        = string
  default     = "t3.micro"
}

variable "nfs_server_ami_id" {
  description = "AMI ID Ubuntu Server 22.04 LTS gốc cho NFS server."
  type        = string
  // QUAN TRỌNG: Lấy AMI ID mới nhất cho Ubuntu 22.04 LTS tại vùng var.aws_region
  // Ví dụ cho us-east-1 (amd64):
  default     = "ami-053b0d53c279acc90" // CẦN KIỂM TRA LẠI!
}

variable "nfs_volume_size_gb" {
  description = "Dung lượng (GB) cho EBS volume của NFS share."
  type        = number
  default     = 50
}

variable "key_pair_name" {
  description = "Tên của EC2 Key Pair ĐÃ TỒN TẠI trong vùng AWS đã chọn."
  type        = string
  default     = "nguyenp-key-pair" // THAY THẾ BẰNG TÊN KEY PAIR CỦA BẠN
}

variable "user_ip_for_access" {
  description = "IP public của bạn để cho phép truy cập SSH/UI. Nếu để trống, IP hiện tại của máy chạy Terraform sẽ được sử dụng."
  type        = string
  default     = "" # Terraform sẽ tự động lấy qua data.http.my_public_ip
}