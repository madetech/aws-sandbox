import os
import logging
import boto3

try:
    # When running under pytest:
    from . import functions
except ImportError:
    # When running in Lambda:
    import functions

# Initialize the logger
logger = logging.getLogger()
logger.setLevel("INFO")

# Set SSM client
ssm = boto3.client("ssm")


def lambda_handler(event, context) -> dict:
    """
    Main Lambda handler function
    Parameters:
        event: Dict containing the Lambda function event data
        context: Lambda runtime context
    Returns:
        Dict containing status message
    """
    try:
        # Access environment variables
        slack_webhook_ssm_parameter_name = os.environ.get(
            "SLACK_WEBHOOK_SSM_PARAMETER_NAME"
        )
        if not slack_webhook_ssm_parameter_name:
            raise ValueError(
                "Missing required environment variable SLACK_WEBHOOK_SSM_PARAMETER_NAME"
            )

        # Get SSM parameter value (raw exception will propagate if missing)
        response = ssm.get_parameter(
            Name=slack_webhook_ssm_parameter_name, WithDecryption=True
        )
        slack_webhook = response["Parameter"]["Value"]
        if not slack_webhook:
            raise ValueError(
                f"SSM parameter '{slack_webhook_ssm_parameter_name}' is empty"
            )

        codebuild_event = functions.get_codebuild_event(event)

        if codebuild_event["detail"]["build-status"] == "SUCCEEDED":
            message = "aws-nuke succeeded."
        else:
            codebuild_run_url = functions.generate_build_url(codebuild_event)
            message = f"aws-nuke has failed. See CodeBuild output here: {codebuild_run_url}"

        functions.post_to_slack(slack_webhook, {"text": message})

        return {"statusCode": 200, "message": "Message successfully delivered to Slack"}
    except Exception as e:
        logger.error(f"Error sending message: {str(e)}")
        raise
