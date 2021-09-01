terraform {
  required_version = ">= 0.15.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "madetech-sandbox-terraform-state"
    key            = "bootstrap.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "sandbox-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "eu-west-2"
}
