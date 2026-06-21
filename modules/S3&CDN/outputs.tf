output "s3" {
  value = aws_s3_bucket.website_bucket
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.cnd_with_waf.domain_name
  description = "The URL to access your secured static website"
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.cnd_with_waf.id
}