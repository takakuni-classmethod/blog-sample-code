#############################
# CloudWatch Logs
#############################
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_s3_bucket.this.bucket}"
  retention_in_days = 14
}

#############################
# IAM Role for Lambda
#############################
resource "aws_iam_role" "lambda" {
  name = "presigned-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda" {
  name = "presigned-lambda-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:*", "s3-object-lambda:*"]
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3" {
  policy_arn = aws_iam_policy.lambda.arn
  role       = aws_iam_role.lambda.name
}

resource "aws_iam_role_policy_attachment" "lambda_managed" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}

#############################
# Lambda Function
#############################
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "presigned-lambda-function"
  role             = aws_iam_role.lambda.arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 128
  architectures = ["x86_64"]

  ephemeral_storage {
    size = 512
  }

  logging_config {
    log_group             = aws_cloudwatch_log_group.lambda.name
    log_format            = "JSON"
    system_log_level      = "INFO"
    application_log_level = "INFO"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_s3,
    aws_iam_role_policy_attachment.lambda_managed,
    aws_cloudwatch_log_group.lambda
  ]
}
