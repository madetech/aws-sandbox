### Use S3 bucket as source, zip up yaml
### Temp until setup connection to github properly

resource "aws_s3_bucket" "this" {
  bucket = "aws-nuke-config-madetech"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "../aws-nuke.yaml"
  output_path = "../aws-nuke.zip"
}

resource "aws_s3_bucket_object" "upload_zip" {
  bucket = "aws-nuke-config-madetech"
  key    = "aws-nuke.zip"
  source = data.archive_file.zip.output_path
}
