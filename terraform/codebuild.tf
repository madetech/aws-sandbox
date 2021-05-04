resource "aws_codestarconnections_connection" "aws_nuke" {
  name          = "sandbox-nuke"
  provider_type = "GitHub"
}

resource "aws_codebuild_project" "aws_nuke" {
  name          = "sandbox-nuke"
  description   = "Nuke Sandbox Weekly"
  build_timeout = "5"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "quay.io/rebuy/aws-nuke:latest"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "S3"
    location  = "arn:aws:s3:::aws-nuke-config-madetech/aws-nuke.zip"
    buildspec = "version: 0.2\n\nphases:\n  build:\n    commands:\n       - aws-nuke --config aws-nuke.yaml --quiet --force"
  }

  tags = {
    Environment = "Sandbox"
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "codebuild-aws-nuke"
  assume_role_policy = data.aws_iam_policy_document.codebuild.json
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "codebuild" {
  role       = aws_iam_role.codebuild.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
