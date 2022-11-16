variable "code_bucket_name" {
  default = "ph-sanity-video-lambda-src"
}

resource "aws_s3_bucket" "code" {
  bucket = var.code_bucket_name
}

data "archive_file" "conversion_lambda_src" {
  type             = "zip"
  source_file      = "${path.module}/src/conversion.js"
  output_file_mode = "0666"
  output_path      = "${path.module}/src/${var.conversion_lambda_function_name}.zip"
}

data "archive_file" "get_signed_url_lambda_src" {
  type             = "zip"
  source_file      = "${path.module}/src/getSignedUrl.js"
  output_file_mode = "0666"
  output_path      = "${path.module}/src/${var.get_signed_url_lambda_function_name}.zip"
}

data "archive_file" "delete_lambda_src" {
  type             = "zip"
  source_file      = "${path.module}/src/delete.js"
  output_file_mode = "0666"
  output_path      = "${path.module}/src/${var.delete_lambda_function_name}.zip"
}

resource "aws_s3_bucket_object" "conversion_code" {
  bucket = aws_s3_bucket.code.id
  key = "conversion.zip"
  source = data.archive_file.conversion_lambda_src.output_path
  etag = filemd5(data.archive_file.conversion_lambda_src.output_path)
}

resource "aws_s3_bucket_object" "get_signed_url_code" {
  bucket = aws_s3_bucket.code.id
  key = "get-signed-url.zip"
  source = data.archive_file.get_signed_url_lambda_src.output_path
  etag = filemd5(data.archive_file.get_signed_url_lambda_src.output_path)
}

resource "aws_s3_bucket_object" "delete_code" {
  bucket = aws_s3_bucket.code.id
  key = "delete.zip"
  source = data.archive_file.delete_lambda_src.output_path
  etag = filemd5(data.archive_file.delete_lambda_src.output_path)
}