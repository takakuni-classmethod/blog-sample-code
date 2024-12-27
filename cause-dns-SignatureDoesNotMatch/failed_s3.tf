# #############################
# # Failed S3 Bucket
# #############################
# resource "aws_s3_bucket" "this_2" {
#   bucket = "presigned.lambda.${local.account_id}"
#   tags = {
#     Name = "presigned.lambda.${local.account_id}"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "this_2" {
#   bucket = aws_s3_bucket.this_2.id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_ownership_controls" "this_2" {
#   bucket = aws_s3_bucket.this_2.id

#   rule {
#     object_ownership = "BucketOwnerEnforced"
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "this_2" {
#   bucket = aws_s3_bucket.this_2.id

#   rule {
#     bucket_key_enabled = true
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# resource "aws_s3_bucket_notification" "this_2" {
#   bucket = aws_s3_bucket.this_2.id

#   lambda_function {
#     lambda_function_arn = aws_lambda_function.this.arn
#     events              = ["s3:ObjectCreated:*"]
#     filter_prefix       = "input/"
#   }

#   depends_on = [aws_lambda_permission.this_2]
# }

# resource "aws_lambda_permission" "this_2" {
#   statement_id  = "AllowS3Invoke2"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.this.function_name
#   principal     = "s3.amazonaws.com"
#   source_arn    = aws_s3_bucket.this_2.arn
# }

# resource "aws_s3_bucket_lifecycle_configuration" "this_2" {
#   bucket = aws_s3_bucket.this_2.id

#   rule {
#     id     = "1Week-Delete"
#     status = "Enabled"

#     filter {
#       prefix = "input/"
#     }

#     expiration {
#       days = 10
#     }
#   }
# }

# #############################
# # S3 Object
# #############################
# resource "aws_s3_object" "test_object_2" {
#   for_each = fileset("./input/", "**")
#   bucket   = aws_s3_bucket.this_2.bucket
#   key      = "input/${each.value}"
#   source   = "./input/${each.value}"
#   etag     = filemd5("./input/${each.value}")

#   depends_on = [aws_lambda_function.this]
# }
