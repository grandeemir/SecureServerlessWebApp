output "api_url" {
  value       = "${aws_apigatewayv2_stage.default_stage.invoke_url}create-item"
  description = "The absolute secure endpoint URL for your frontend application"
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

