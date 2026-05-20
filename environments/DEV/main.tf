module "s3" {
  source               = "../../modules/S3&CDN"
  tags                 = local.common_tags
  bucket_name          = "secure-file-vaulth-app-bucket"
  cognito_client_id    = module.cognito.user_pool_client_id
  cognito_user_pool_id = module.cognito.user_pool_id
  cognito_domain       = module.cognito.cognito_domain
  api_endpoint         = module.api.api_endpoint
  web_acl_id           = module.waf_cloudfront.web_acl_arn
}

module "waf_cloudfront" {
  source = "../../modules/waf"
  name   = "AetherVault-WAF-CloudFront"
  scope  = "CLOUDFRONT"
  tags   = local.common_tags

  providers = {
    aws = aws.us_east_1
  }
}

module "waf_api" {
  source = "../../modules/waf"
  name   = "AetherVault-WAF-API"
  scope  = "REGIONAL"
  tags   = local.common_tags
}

module "cognito" {
  source       = "../../modules/cognito"
  tags         = local.common_tags
  callback_url = "https://${module.s3.cloudfront_domain_name}/vault.html"
}

module "lambda" {
  source              = "../../modules/lambda"
  tags                = local.common_tags
  table_name          = module.dynamoDB.table_name
  table_arn           = module.dynamoDB.table_arn
  storage_bucket_name = module.s3_storage.bucket_name
  storage_bucket_arn  = module.s3_storage.bucket_arn
}

module "dynamoDB" {
  source       = "../../modules/dynamoDB"
  table_name   = "AetherVault-Files"
  tags         = local.common_tags
  billing_mode = "PAY_PER_REQUEST"
}

module "s3_storage" {
  source      = "../../modules/s3_storage"
  bucket_name = "aethervault-user-storage"
  tags        = local.common_tags
}

module "api" {
  source = "../../modules/api_gw"
  tags   = local.common_tags

  cognito_user_pool_id = module.cognito.user_pool_id
  cognito_client_id    = module.cognito.user_pool_client_id
  aws_region           = "us-east-1"
  lambda_function_arn  = module.lambda.lambda_function
  lambda_function_name = module.lambda.lambda_function_name
}
