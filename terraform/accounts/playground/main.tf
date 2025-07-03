terraform {
  # Todo: Bring this up to date once other things are working
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # Todo: Bring this up to date once other things are working
      version = "~> 3.0"
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

module "nuke" {
  source = "../../modules/nuke_pipeline"

  cron_schedule        = "cron(0 20 ? * FRI *)"
}
