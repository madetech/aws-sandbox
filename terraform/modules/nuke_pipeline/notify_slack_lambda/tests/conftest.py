import os

# Tests shouldn't require working AWS credentials, but the boto3 library
# requires a region to be defined even if no requests are going to be made.
os.environ.setdefault("AWS_DEFAULT_REGION", "dummy")
