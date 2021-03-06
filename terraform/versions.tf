terraform {
  required_version = ">= 0.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
    archive = {
      source = "hashicorp/archive"
    }
  }

  backend "s3" {
    bucket         = "madetech-sandbox-terraform-state"
    key            = "sandbox.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "sandbox-terraform-locks"
    encrypt        = true
  }
}
