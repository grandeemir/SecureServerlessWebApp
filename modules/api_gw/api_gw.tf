# 1. The HTTP API Gateway Core
resource "aws_apigatewayv2_api" "http_api" {
  name          = "filevault-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"] # Security note: Tighten this to your CloudFront domain later
    allow_methods = ["POST", "GET", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
  }

  tags = var.tags
}

# 2. The Zero Trust Gatekeeper (Validates Cognito JWTs automatically)
resource "aws_apigatewayv2_authorizer" "cognito_auth" {
  api_id           = aws_apigatewayv2_api.http_api.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-jwt-authorizer"

  jwt_configuration {
    audience = [var.cognito_client_id]
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

# 3. The API Stage (Forces instant deployment on changes)
resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

# 4. Protected Routes for File Vault
resource "aws_apigatewayv2_route" "list_files" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /files"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "upload_url" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /files/upload-url"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "record_metadata" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /files"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "download_url" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "GET /files/{id}/download-url"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "delete_file" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "DELETE /files/{id}"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_auth.id
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# 5. Integration linking the Gateway to your Lambda function
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = var.lambda_function_arn
  payload_format_version = "2.0"
}

# 6. AWS Security Handshake: Grant API Gateway explicit permission to call Lambda
resource "aws_lambda_permission" "api_gw_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}