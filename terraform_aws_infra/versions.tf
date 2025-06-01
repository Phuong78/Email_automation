terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Luôn kiểm tra phiên bản AWS provider mới nhất
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }

  # backend "s3" { # Cấu hình S3 backend để lưu state (khuyến nghị cho làm việc nhóm/production)
  #   bucket         = "YOUR_TERRAFORM_STATE_BUCKET_NAME"
  #   key            = "email-service/main-infra/terraform.tfstate"
  #   region         = "YOUR_BUCKET_REGION" # ví dụ: us-east-1
  #   encrypt        = true
  #   # dynamodb_table = "YOUR_TERRAFORM_LOCK_TABLE" # Cho state locking
  # }
}