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
