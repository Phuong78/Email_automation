provider "aws" {
  region = var.aws_region
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