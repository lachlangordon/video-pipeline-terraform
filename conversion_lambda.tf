data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

variable "conversion_lambda_function_name" {
  default = "create-sanity-video-job-lambda"
}

//Define lambda function and code

resource "aws_lambda_function" "conversion_lambda" {
  runtime       = "nodejs16.x"
  s3_bucket = aws_s3_bucket.code.id
  s3_key = aws_s3_bucket_object.conversion_code.key
  source_code_hash = data.archive_file.conversion_lambda_src.output_base64sha256
  function_name = var.conversion_lambda_function_name
  handler       = "conversion.handler"
  role          = aws_iam_role.conversion_lambda_role.arn
  timeout       = 900

  environment {
    variables = {
      queue = aws_media_convert_queue.queue.arn
      role  = aws_iam_role.mediaconvert_role.arn
      destination = aws_s3_bucket.destination.id
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.conversion_lambda_logging_policy_attachment,
    aws_cloudwatch_log_group.conversion_lambda_logging
  ]
}

//Define lambda function's execution role

data "aws_iam_policy_document" "conversion_lambda_role_assume_role_policy_document" {
  statement {
    sid     = "AllowAssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "conversion_lambda_role" {
  name               = "${var.conversion_lambda_function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.conversion_lambda_role_assume_role_policy_document.json
}

//Define lambda function's s3 access

data "aws_iam_policy_document" "conversion_lambda_role_s3_execution_policy_document" {
  statement {
    sid       = "AllowS3Access"
    actions   = ["s3:GetObject"]
    resources = [aws_s3_bucket.source.arn]
  }
}

resource "aws_iam_policy" "conversion_lambda_s3_policy" {
  name        = "${var.conversion_lambda_function_name}-s3-policy"
  path        = "/"
  description = "Allows video pipeline lambda to read objects from a source bucket"
  policy      = data.aws_iam_policy_document.conversion_lambda_role_s3_execution_policy_document.json
}

resource "aws_iam_role_policy_attachment" "conversion_lambda_s3_policy_attachment" {
  role       = aws_iam_role.conversion_lambda_role.name
  policy_arn = aws_iam_policy.conversion_lambda_s3_policy.arn
}

//Define lambda function's MediaConvert access

data "aws_iam_policy_document" "conversion_lambda_role_mediaconvert_policy_document" {
  statement {
    sid       = "AllowMediaConvertAccess"
    actions   = ["mediaconvert:CreateJob"]
    resources = [aws_media_convert_queue.queue.arn]
  }
  statement {
    sid       = "AllowMediaConvertPassRole"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.mediaconvert_role.arn]
  }
  statement {
    sid = "AllowMediaConvertDescribeEndpoints"
    actions = ["mediaconvert:DescribeEndpoints"]
    resources = ["arn:aws:mediaconvert:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:endpoints/*"]
  }
}

resource "aws_iam_policy" "conversion_lambda-mediaconvert-policy" {
  name        = "${var.conversion_lambda_function_name}-mediaconvert-policy"
  path        = "/"
  description = "Allows video pipeline lambda to create MediaConvert jobs"
  policy      = data.aws_iam_policy_document.conversion_lambda_role_mediaconvert_policy_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_role_mediaconvert_policy_attachment" {
  role       = aws_iam_role.conversion_lambda_role.name
  policy_arn = aws_iam_policy.conversion_lambda-mediaconvert-policy.arn
}

//Define lambda function's Cloudwatch logs and permissions

resource "aws_cloudwatch_log_group" "conversion_lambda_logging" {
  name              = "/aws/lambda/${var.conversion_lambda_function_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "conversion_lambda_role_logging_policy_document" {
  statement {
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
  }
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["${aws_cloudwatch_log_group.conversion_lambda_logging.arn}:*"]
  }
}

resource "aws_iam_policy" "conversion_lambda_logging_policy" {
  name        = "${var.conversion_lambda_function_name}-logging-policy"
  path        = "/"
  description = "policy for logging output from video processing function"
  policy      = data.aws_iam_policy_document.conversion_lambda_role_logging_policy_document.json
}

resource "aws_iam_role_policy_attachment" "conversion_lambda_logging_policy_attachment" {
  role       = aws_iam_role.conversion_lambda_role.name
  policy_arn = aws_iam_policy.conversion_lambda_logging_policy.arn
}


