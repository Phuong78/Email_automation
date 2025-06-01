provider "aws" {
  region = var.aws_region
  # AWS credentials sẽ được lấy từ AWS CLI đã cấu hình trên máy Mac của bạn
  # hoặc từ environment variables, hoặc IAM role (nếu chạy Terraform từ EC2)
}

data "http" "my_public_ip" {
  url = "https://checkip.amazonaws.com"
}

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}