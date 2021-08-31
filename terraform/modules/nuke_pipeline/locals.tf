locals {
  name     = "sandbox-nuke"
  schedule = "cron(0 20 ? * FRI *)"

  common_tags = {
    Environment = "Sandbox"
    Project     = "aws-nuke"
  }
}
