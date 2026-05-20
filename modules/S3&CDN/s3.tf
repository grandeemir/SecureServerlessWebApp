resource "random_id" "bucket_id" {
  byte_length = 4
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "${var.bucket_name}-${random_id.bucket_id.hex}"
  lifecycle {
    prevent_destroy = false
  }
  tags = merge(
    var.tags,
    {
      Name = var.bucket_name
    }
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.website_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "website_files" {
  for_each = {
    for f in fileset("../../scripts/website", "**/*") : f => f
    if f != "config.js" && f != "auth.html" && f != "auth.js"
  }

  bucket = aws_s3_bucket.website_bucket.id

  key    = each.value
  source = "../../scripts/website/${each.value}"

  etag = filemd5("../../scripts/website/${each.value}")

  content_type = lookup({
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    png  = "image/png"
    jpg  = "image/jpeg"
  }, split(".", each.value)[length(split(".", each.value)) - 1], "binary/octet-stream")
}

resource "aws_s3_object" "config_js" {
  bucket = aws_s3_bucket.website_bucket.id
  key    = "config.js"
  content = templatefile("../../scripts/website/config.js", {
    user_pool_id        = var.cognito_user_pool_id
    user_pool_client_id = var.cognito_client_id
    cognito_domain      = var.cognito_domain
    api_endpoint        = var.api_endpoint
  })
  content_type = "application/javascript"
}

resource "aws_s3_bucket_public_access_block" "allow" {
  bucket                  = aws_s3_bucket.website_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-oac-${aws_s3_bucket.website_bucket.id}"
  description                       = "OAC for securing static website S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cnd_with_waf" {
  
  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = "S3Origin"
  }

  enabled             = true
  is_ipv6_enabled     = false
  default_root_object = "index.html"

  # Default cache behavior settings
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https" # Enforce HTTPS
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = var.web_acl_id

  tags = var.tags
}

resource "aws_s3_bucket_policy" "allow_access_from_cloudfront" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = data.aws_iam_policy_document.cloudfront_oac_policy.json
}

data "aws_iam_policy_document" "cloudfront_oac_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.website_bucket.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.cnd_with_waf.arn]
    }
  }
}

