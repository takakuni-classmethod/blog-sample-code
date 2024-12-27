#############################
# S3 Bucket
#############################
resource "aws_s3_bucket" "this" {
  bucket = "presigned-lambda2-${local.account_id}"
  tags = {
    Name = "presigned-lambda2-${local.account_id}"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_notification" "this" {
  bucket = aws_s3_bucket.this.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.this.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/"
  }

  depends_on = [aws_lambda_permission.this]
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.this.arn
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "1Week-Delete"
    status = "Enabled"

    filter {
      prefix = "input/"
    }

    expiration {
      days = 10
    }
  }
}

#############################
# S3 Object
#############################
resource "aws_s3_object" "test_object" {
  for_each = fileset("./input/", "**")
  bucket   = aws_s3_bucket.this.bucket
  key      = "input/${each.value}"
  source   = "./input/${each.value}"
  etag     = filemd5("./input/${each.value}")

  depends_on = [aws_lambda_function.this]
}
