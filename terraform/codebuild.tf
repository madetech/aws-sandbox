resource "aws_codestarconnections_connection" "aws_nuke" {
  name          = "sandbox-nuke"
  provider_type = "GitHub"
}

resource "aws_codebuild_project" "aws_nuke" {
  name           = "sandbox-nuke"
  description    = "Nuke Sandbox Weekly"
  build_timeout  = "5"
  service_role   = aws_iam_role.codebuild.arn
  source_version = "main"

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
    git_clone_depth = 1
    type            = "GITHUB"
    location        = "https://github.com/madetech/aws-sandbox.git"
    buildspec       = "buildspec.yml"
    git_submodules_config {
      fetch_submodules = false
    }
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
