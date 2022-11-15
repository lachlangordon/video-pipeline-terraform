variable "sanity-s3-apigw-name" {
  default = "sanity-s3-apigw"
}

resource "aws_apigatewayv2_api" "sanity-s3-api" {
  name          = var.sanity-s3-apigw-name
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"] //This needs to be something real, and apigw wont accept localhost as valid
    allow_methods = ["GET", "POST", "DELETE", "OPTIONS"]
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
  }
}

resource "aws_apigatewayv2_stage" "test" {
  api_id = aws_apigatewayv2_api.sanity-s3-api.id
  name = "test"
  auto_deploy = true
}

resource "aws_apigatewayv2_deployment" "deployment" {
  api_id = aws_apigatewayv2_api.sanity-s3-api.id

  depends_on = [
    aws_apigatewayv2_route.delete,
    aws_apigatewayv2_route.get
  ]
}

resource "aws_apigatewayv2_integration" "get_lambda" {
  api_id             = aws_apigatewayv2_api.sanity-s3-api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.get_signed_url_lambda.invoke_arn

}

resource "aws_apigatewayv2_route" "get" {
  api_id    = aws_apigatewayv2_api.sanity-s3-api.id
  route_key = "ANY /get"
  target    = "integrations/${aws_apigatewayv2_integration.get_lambda.id}"
}

resource "aws_lambda_permission" "apigw_get_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_signed_url_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.sanity-s3-api.execution_arn}/*/*/get"
}

resource "aws_apigatewayv2_integration" "delete_lambda" {
  api_id             = aws_apigatewayv2_api.sanity-s3-api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.delete_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "delete" {
  api_id    = aws_apigatewayv2_api.sanity-s3-api.id
  route_key = "ANY /delete"
  target    = "integrations/${aws_apigatewayv2_integration.delete_lambda.id}"
}

resource "aws_lambda_permission" "apigw_delete_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvokation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.sanity-s3-api.execution_arn}/*/*/delete"
}