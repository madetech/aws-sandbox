terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "madetech-devops-sandbox-terraform-state"
    key            = "sandbox.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "sandbox-terraform-locks"
    encrypt        = true
  }
}

module "nuke" {
  source = "../../modules/nuke_pipeline"
}
