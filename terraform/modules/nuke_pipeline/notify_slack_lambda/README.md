# Slack Webhook Lambda

This Lambda is triggered whenever the `sandbox-nuke` CodeBuild build run fails. If this happens, the Lambda sends a notification to the `#cop-cloud` Slack channel with a URL to the failed build run.

## Testing with Pytest

```sh
# Install all dependencies:
uv sync

# Run the tests:
uv run pytest
```
