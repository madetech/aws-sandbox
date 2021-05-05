data "aws_iam_policy_document" "cloudwatch" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudwatch" {
  name               = "cloudwatch-${local.name}"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "cloudwatch-${local.name}"
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
  name                = local.name
  description         = "Cron to nuke sandbox resources"
  schedule_expression = local.schedule
  tags                = local.common_tags
}

resource "aws_cloudwatch_event_target" "trigger_build" {
  target_id = "trigger_build"
  rule      = aws_cloudwatch_event_rule.codebuild.name
  arn       = aws_codebuild_project.aws_nuke.id
  role_arn  = aws_iam_role.cloudwatch.arn
}
