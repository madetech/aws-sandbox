resource "aws_codestarnotifications_notification_rule" "aws_nuke" {
  detail_type    = "BASIC"
  event_type_ids = ["codebuild-project-build-state-failed", "codebuild-project-build-state-succeeded"]
  name           = local.name
  resource       = aws_codebuild_project.aws_nuke.arn
  target {
    address = aws_sns_topic.completions.arn
  }
}

resource "aws_sns_topic" "completions" {
  name                             = "completions-${local.name}"
  lambda_failure_feedback_role_arn = aws_iam_role.sns_logging.arn
}

resource "aws_sns_topic_policy" "completions" {
  arn    = aws_sns_topic.completions.arn
  policy = data.aws_iam_policy_document.completions_topic.json
}

data "aws_iam_policy_document" "completions_topic" {
  statement {
    actions = ["sns:Publish"]
    principals {
      type        = "Service"
      identifiers = ["codestar-notifications.amazonaws.com"]
    }
    resources = [aws_sns_topic.completions.arn]
  }
}

resource "aws_iam_role" "sns_logging" {
  name               = "sns-logging-${local.name}"
  assume_role_policy = data.aws_iam_policy_document.sns_logging_assume_role.json
}

data "aws_iam_policy_document" "sns_logging_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "sns_logging" {
  name   = "sns-logging-${local.name}"
  role   = aws_iam_role.sns_logging.name
  policy = data.aws_iam_policy_document.sns_logging.json
}

data "aws_iam_policy_document" "sns_logging" {
  statement {
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }
}

resource "aws_sns_topic_subscription" "completions" {
  topic_arn = aws_sns_topic.completions.arn
  protocol  = "lambda"
  endpoint  = module.notify_slack_lambda.lambda_function_arn
}

module "notify_slack_lambda" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "notify-slack-${local.name}"
  runtime       = "python3.13"
  architectures = ["arm64"]
  source_path = [{
    path = "${path.module}/notify_slack_lambda"
    patterns = [
      "src/*.py",
      "pyproject.toml",
      "uv.lock",
    ]
    commands = [
      ":zip src .",
      "rm -rf ../tfbuild/lambda/vendor",
      "mkdir -p ../tfbuild/lambda/vendor",
      "uv sync",
      "uv export --no-default-groups > ../tfbuild/lambda/requirements.txt",
      "pip3 install --target=../tfbuild/lambda/vendor -r ../tfbuild/lambda/requirements.txt",
      ":zip ../tfbuild/lambda/vendor .",
    ]
  }]
  handler = "main.lambda_handler"
  environment_variables = {
    SLACK_WEBHOOK_SSM_PARAMETER_NAME = data.aws_ssm_parameter.slack_webhook.name
  }
  publish            = true
  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.notify_slack_lambda.json
  artifacts_dir      = "${path.module}/tfbuild/lambda/artifacts"
  allowed_triggers = {
    sns = {
      service    = "sns"
      source_arn = aws_sns_topic.completions.arn
    }
  }
}

data "aws_iam_policy_document" "notify_slack_lambda" {
  statement {
    actions   = ["ssm:GetParameter"]
    resources = [data.aws_ssm_parameter.slack_webhook.arn]
  }
}

data "aws_ssm_parameter" "slack_webhook" {
  name            = "/${local.name}/slack-webhook"
  with_decryption = false
}
