import json
import requests
from urllib.parse import quote


def get_codebuild_event(sns_event: dict) -> dict:
    """
    Function for extracting the CodeBuild success/failure event
    out of an SNS event.
    """
    return json.loads(sns_event["Records"][0]["Sns"]["Message"])


def generate_build_url(data: dict) -> str:
    """
    Function for generating a URL for the CodeBuild Project run
    Parameters:
        data: Dict containing information about the build run
    Returns:
        Str containing the URL
    """
    aws_account = data["account"]
    aws_region = data["region"]
    project_name = data["detail"]["project-name"]
    codebuild_run = data["detail"]["build-id"].split("build/")[1]
    codebuild_run_encoded = quote(codebuild_run, safe="")
    codebuild_run_url = f"https://{aws_region}.console.aws.amazon.com/codesuite/codebuild/{aws_account}/projects/{project_name}/build/{codebuild_run_encoded}/?region={aws_region}"
    return codebuild_run_url


def post_to_slack(url: str, payload: dict) -> dict:
    """
    Function for posting payload to Slack channel
    Parameters:
        url: Str containing the Webhook URL
        payload: Dict containing the payload
    Returns:
        Dict containing status message
    """
    response = requests.post(url, json=payload)
    response.raise_for_status()  # raises HTTPError for 4xx/5xx
    return {
        "success": response.ok,
        "status_code": response.status_code,
        "message": "Message successfully delivered to Slack",
        "response_body": response.text,
    }
