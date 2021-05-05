locals {
  name     = "sandbox-nuke"
  schedule = "rate(1 hour)"
  common_tags = {
    Environment = "Sandbox"
    Project     = "aws-nuke"
  }
}
