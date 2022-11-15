variable "source_bucket_name" {
  default = "ph-sanity-video"
}

resource "aws_s3_bucket" "source" {
  bucket = var.source_bucket_name
}

resource "aws_s3_bucket_cors_configuration" "source_cors" {
  bucket = aws_s3_bucket.source.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST"]
    allowed_origins = ["http://localhost:3333"]
  }
}

resource "aws_s3_bucket_ownership_controls" "sanity_upload_access" {
  bucket = aws_s3_bucket.source.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_notification" "sanity_upload_event" {
  bucket = aws_s3_bucket.source.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.conversion_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".mp4"
  }

  depends_on = [aws_lambda_permission.enable_lambda_trigger]
}

resource "aws_lambda_permission" "enable_lambda_trigger" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.conversion_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.source.arn
}