# AWS Sandbox Nuke

## Purpose

This repo contains the config to periodically clean the AWS Sandbox account of all
resources using `aws-nuke`. It also contains the Terraform to deploy the AWS resources
required to run this job remotely.

It is possible to exclude resources you wish to retain by adding them to the `aws-nuke.yaml` config file.

## Repository Structure
- `aws-nuke.yaml` config file is used by [aws-nuke](https://github.com/rebuy-de/aws-nuke#readme)
- `buildspec.yml` is used by AWS CodeBuild
- Terraform IAC code is within the `terraform` directory
- Terraform IAC initial setup code for state file bucket/dynamodb is within the `terraform/bootstrap` directory

## Test Locally

Test locally after updating `aws-nuke.yaml`...

```shell
aws-vault exec madesso -- aws-nuke run -c aws-nuke.yaml -q --force
```

By default `aws-nuke` runs in dry-run mode. To really delete things, add the `--no-dry-run` flag.
