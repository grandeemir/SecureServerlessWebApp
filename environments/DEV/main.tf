module "s3" {
  source      = "../../modules/S3&CDN"
  tags        = local.common_tags
  bucket_name = "secure-file-vaulth-app-bucket"
}

module "cognito" {
  source       = "../../modules/cognito"
  tags         = local.common_tags
  callback_url = "https://${module.s3.cloudfront_domain_name}/vault.html"
}

resource "aws_s3_object" "config_js" {
  bucket = module.s3.s3.id
  key    = "config.js"
  content = templatefile("../../scripts/website/config.js", {
    user_pool_id        = module.cognito.user_pool_id
    user_pool_client_id = module.cognito.user_pool_client_id
    cognito_domain      = module.cognito.cognito_domain
  })
  content_type = "application/javascript"
}

module "lambda" {
  source = "../../modules/lambda"
  tags   = local.common_tags
}

module "api_gw" {
  source               = "../../modules/api_gw"
  tags                 = local.common_tags
  cognito_client_id    = module.cognito.user_pool_client_id
  cognito_user_pool_id = module.cognito.user_pool_id
  aws_region           = var.aws_region
  lambda_function_arn  = module.lambda.function.arn
  lambda_function_name = module.lambda.function_name
}

