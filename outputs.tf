output "cloudfront_url" {
  description = "CloudFront distribution URL for the web app"
  value       = "https://${aws_cloudfront_distribution.web.domain_name}"
}

output "api_endpoint" {
  description = "Direct API Gateway endpoint"
  value       = aws_apigatewayv2_api.api.api_endpoint
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.users.id
}

output "cognito_app_client_id" {
  description = "Cognito app client ID"
  value       = aws_cognito_user_pool_client.web.id
}

output "s3_bucket_name" {
  description = "Private S3 bucket that stores the web app"
  value       = aws_s3_bucket.web.bucket
}
