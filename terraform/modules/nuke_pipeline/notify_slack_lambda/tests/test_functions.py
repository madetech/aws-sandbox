import pytest
from src import functions
import requests


def test_get_codebuild_event():
    input = {
        "Records": [
            {
                "EventSource": "aws:sns",
                "EventVersion": "1.0",
                "Sns": {
                    "Type": "Notification",
                    "Message": """{"account":"261219435789","region":"eu-west-2"}""",
                },
            }
        ],
    }
    expected = {
        "account": "261219435789",
        "region": "eu-west-2",
    }
    assert functions.get_codebuild_event(input) == expected


@pytest.mark.parametrize(
    "input,expected",
    [
        (
            {
                "account": "test-account",
                "region": "test-region",
                "detail": {
                    "project-name": "test-project",
                    "build-id": "arn:aws:codebuild:test-region:test-account:build/test-project:some-id-1",
                },
            },
            "https://test-region.console.aws.amazon.com/codesuite/codebuild/test-account/projects/test-project/build/test-project%3Asome-id-1/?region=test-region",
        ),
        (
            {
                "account": "test-account",
                "region": "test-region",
                "detail": {
                    "project-name": "test-project",
                    "build-id": "arn:aws:codebuild:test-region:test-account:build/test-project:some-id-2",
                },
            },
            "https://test-region.console.aws.amazon.com/codesuite/codebuild/test-account/projects/test-project/build/test-project%3Asome-id-2/?region=test-region",
        ),
    ],
)
def test_generate_build_url(input, expected):
    result = functions.generate_build_url(input)

    assert result == expected


def test_post_message(mocker):
    mock_response = mocker.Mock(ok=True)
    mocker.patch("src.functions.requests.post", return_value=mock_response)

    result = functions.post_to_slack("https://example.com", {"data": "x"})

    assert result["success"] is True


@pytest.fixture
def mock_requests_post(mocker):
    def _mock_requests_post(side_effect):
        mocker.patch("src.functions.requests.post", side_effect=side_effect)

    return _mock_requests_post


@pytest.mark.parametrize(
    "exception, match",
    [
        (requests.ConnectionError("Connection failed"), "Connection failed"),
        (requests.HTTPError("404 Not Found"), "404 Not Found"),
        (requests.Timeout("Request timed out"), "Request timed out"),
        (requests.TooManyRedirects("Too many redirects"), "Too many redirects"),
    ],
)
def test_post_to_slack_exceptions(mock_requests_post, exception, match):
    mock_requests_post(exception)

    with pytest.raises(type(exception), match=match):
        functions.post_to_slack("https://example.com", {"data": "x"})
