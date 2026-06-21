output "website_url" {
  value       = module.s3.cloudfront_domain_name
  description = "The CloudFront URL for the website"
}

output "cognito_user_pool_id" {
  value = module.cognito.user_pool_id
}

output "cognito_client_id" {
  value = module.cognito.user_pool_client_id
}

output "cognito_domain" {
  value = module.cognito.cognito_domain
}

output "api_endpoint" {
  value = module.api.api_endpoint
}

output "frontend_bucket_name" {
  value = module.s3.s3.bucket
}

output "cloudfront_distribution_id" {
  value = module.s3.cloudfront_distribution_id
}
