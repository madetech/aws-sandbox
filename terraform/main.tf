### Use S3 bucket as source, zip up yaml

resource "aws_s3_bucket" "this" {
  bucket = "aws-nuke-config-madetech"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "../aws-nuke.yaml"
  output_path = "../aws-nuke.zip"
}

resource "aws_s3_bucket_object" "upload_zip" {
  bucket = "aws-nuke-config-madetech"
  key    = "aws-nuke.zip"
  source = data.archive_file.zip.output_path
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

### Codebuild IAM

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

### Cloudwatch Event & related IAM

resource "aws_iam_role" "cloudwatch" {
  name = "cloudwatch_events_assume"

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
DOC
}

resource "aws_iam_role_policy" "cloudwatch_events_start_codebuild" {
  name = "cloudwatch_events_start_codebuild"
  role = aws_iam_role.cloudwatch.id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "codebuild:StartBuild",
            "Resource": "${aws_codebuild_project.aws_nuke.arn}"
        }
    ]
}
DOC
}

resource "aws_cloudwatch_event_rule" "codebuild" {
  name                = "codebuild-nuke-cron"
  description         = "Cron to nuke sandbox resources"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "trigger_build" {
  target_id = "trigger_build"
  rule      = aws_cloudwatch_event_rule.codebuild.name
  arn       = aws_codebuild_project.aws_nuke.id
  role_arn  = aws_iam_role.cloudwatch.arn
}
