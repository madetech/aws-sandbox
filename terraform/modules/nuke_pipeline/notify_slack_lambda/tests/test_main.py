import pytest
from src import main

# Variables and helper functions reused across tests in this file
test_event = {
    "Records": [
        {
            "EventSource": "aws:sns",
            "EventVersion": "1.0",
            "Sns": {
                "Type": "Notification",
                "Message": """{
                    "account": "test-account",
                    "region": "test-region",
                    "detail": {
                        "project-name": "test-project",
                        "build-id": "arn:aws:codebuild:test-region:test-account:build/test-project:some-id-1",
                    },
                }""",
            },
        }
    ],
}


def setup_common_mocks(mocker, build_status):
    mocker.patch.dict("os.environ", {"SLACK_WEBHOOK_SSM_PARAMETER_NAME": "fake"})

    mocker.patch.object(main.ssm, "get_parameter")
    main.ssm.get_parameter.return_value = {
        "Parameter": {"Value": "https://example.com/webhook"}
    }

    mocker.patch(
        "src.main.functions.get_codebuild_event",
        return_value={"detail": {"build-status": build_status}},
    )

    mocker.patch(
        "src.main.functions.generate_build_url", return_value="https://fake-build-url"
    )

    mocker.patch("src.main.functions.post_to_slack")


# Tests
def test_missing_ssm_env_variable(monkeypatch):
    monkeypatch.delenv("SLACK_WEBHOOK_SSM_PARAMETER_NAME", raising=False)
    with pytest.raises(
        ValueError,
        match="Missing required environment variable SLACK_WEBHOOK_SSM_PARAMETER_NAME",
    ):
        main.lambda_handler(event=None, context=None)


def test_ssm_parameter_not_found(mocker):
    mocker.patch.object(main.ssm, "get_parameter")
    error_response = {"Error": {"Code": "ParameterNotFound", "Message": "Not found"}}
    main.ssm.get_parameter.side_effect = main.ssm.exceptions.ParameterNotFound(
        error_response, "GetParameter"
    )
    mocker.patch.dict("os.environ", {"SLACK_WEBHOOK_SSM_PARAMETER_NAME": "fake"})

    with pytest.raises(main.ssm.exceptions.ParameterNotFound):
        main.lambda_handler(event=None, context=None)


def test_missing_slack_webhook_parameter_value(mocker):
    mocker.patch.dict("os.environ", {"SLACK_WEBHOOK_SSM_PARAMETER_NAME": "fake"})
    mocker.patch.object(main.ssm, "get_parameter")
    main.ssm.get_parameter.return_value = {"Parameter": {"Value": ""}}

    with pytest.raises(ValueError, match="SSM parameter 'fake' is empty"):
        main.lambda_handler(event=None, context=None)


def test_end_to_end_lambda_handler_for_success(mocker):
    setup_common_mocks(mocker, build_status="SUCCEEDED")
    main.lambda_handler(test_event, context=None)
    main.functions.post_to_slack.assert_called_with(
        "https://example.com/webhook",
        {"text": f"aws-nuke succeeded."},
    )


def test_end_to_end_lambda_handler_for_failure(mocker):
    setup_common_mocks(mocker, build_status="FAILED")
    main.lambda_handler(test_event, context=None)
    main.functions.post_to_slack.assert_called_with(
        "https://example.com/webhook",
        {"text": f"aws-nuke has failed. See CodeBuild output here: https://fake-build-url"},
    )
