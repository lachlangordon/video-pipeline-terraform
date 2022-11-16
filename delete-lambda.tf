variable "delete_lambda_function_name" {
  default = "delete-lambda"
}

resource "aws_lambda_function" "delete_lambda" {
  runtime       = "nodejs16.x"
  s3_bucket = aws_s3_bucket.code.id
  s3_key = aws_s3_bucket_object.delete_code.key
  source_code_hash = data.archive_file.delete_lambda_src.output_base64sha256
  function_name = var.delete_lambda_function_name
  handler       = "delete.handler"
  role          = aws_iam_role.delete_lambda_role.arn

  environment {
    variables = {
      bucket = aws_s3_bucket.source.bucket
      region = aws_s3_bucket.source.region
      //De-hardcode this and handle it nicely with secrets manager
      secret = "testkey"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.delete_lambda_logging_policy_attachment,
    aws_cloudwatch_log_group.delete_lambda_logging
  ]
}

data "aws_iam_policy_document" "delete_lambda_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "delete_lambda_role" {
  name               = "${var.delete_lambda_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.delete_lambda_role_policy_document.json
}

data "aws_iam_policy_document" "delete_lambda_s3_policy_document" {
  statement {
    sid       = "AllowS3Access"
    actions   = ["s3:DeleteObject"]
    resources = ["${aws_s3_bucket.source.arn}/*"]
  }
}

resource "aws_iam_policy" "delete_lambda_s3_policy" {
  name        = "${var.delete_lambda_function_name}-s3-policy"
  path        = "/"
  description = "Allows Sanity lambda to delete assets from S3"
  policy      = data.aws_iam_policy_document.delete_lambda_s3_policy_document.json
}

resource "aws_iam_role_policy_attachment" "delete_lambda_s3_policy_attachment" {
  role       = aws_iam_role.delete_lambda_role.name
  policy_arn = aws_iam_policy.delete_lambda_s3_policy.arn
}

resource "aws_cloudwatch_log_group" "delete_lambda_logging" {
  name              = "/aws/lambda/${var.delete_lambda_function_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "delete_lambda_logging_policy_document" {
  statement {
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.delete_lambda_logging.arn}:*"]
  }
}

resource "aws_iam_policy" "delete_lambda_logging_policy" {
  name        = "${var.delete_lambda_function_name}-logging-policy"
  path        = "/"
  description = "Policy for logging output of sanity s3 delete function"
  policy      = data.aws_iam_policy_document.delete_lambda_logging_policy_document.json
}

resource "aws_iam_role_policy_attachment" "delete_lambda_logging_policy_attachment" {
  role       = aws_iam_role.delete_lambda_role.name
  policy_arn = aws_iam_policy.get_signed_url_lambda_logging_policy.arn
}