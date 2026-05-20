terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      version = ">= 5.0"
    }
  }
  backend "s3" {
    key            = "zeroTrustServerlessApp/terraform.tfstate"
    bucket         = "my-terraform-state-01419a9d"
    dynamodb_table = "terraform-state-locks"
    region         = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}