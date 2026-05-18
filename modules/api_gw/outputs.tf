output "api_url" {
  value       = "${aws_apigatewayv2_stage.default_stage.invoke_url}create-item"
  description = "The absolute secure endpoint URL for your frontend application"
}