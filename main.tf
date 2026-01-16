terraform {
  backend "s3" {
    bucket = "tf-state-ecs-demo-bucket"
    key    = "prod/ecs/terraform.tfstate"
    region = "us-east-1"

  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.28.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
