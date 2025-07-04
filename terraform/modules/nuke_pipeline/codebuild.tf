resource "aws_codestarconnections_connection" "aws_nuke" {
  name          = local.name
  provider_type = "GitHub"
  tags          = local.common_tags
}

resource "aws_codebuild_project" "aws_nuke" {
  name           = local.name
  description    = "Nuke Sandbox Weekly"
  build_timeout  = "60"
  service_role   = aws_iam_role.codebuild.arn
  # Todo: revert this after testing
  # source_version = "main"
  source_version = "use-ekristen-fork-of-aws-nuke"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "ghcr.io/ekristen/aws-nuke:v3.56.2"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    git_clone_depth = 1
    type            = "GITHUB"
    location        = "https://github.com/madetech/aws-sandbox.git"
    buildspec       = "buildspec.yaml"
    git_submodules_config {
      fetch_submodules = false
    }
  }

  tags = local.common_tags
}

resource "aws_iam_role" "codebuild" {
  name               = "codebuild-${local.name}"
  assume_role_policy = data.aws_iam_policy_document.codebuild.json
  tags               = local.common_tags
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
