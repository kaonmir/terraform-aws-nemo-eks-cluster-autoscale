terraform {
  required_version = ">= 0.12"
}

# aws 관련 기능을 가지고 있는 모듈
provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "aws"
}
