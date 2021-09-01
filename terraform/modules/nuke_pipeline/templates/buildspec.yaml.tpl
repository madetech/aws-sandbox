---
version: 0.2

phases:
  build:
    commands:
      - aws-nuke --config ${filename} --quiet --force --no-dry-run
