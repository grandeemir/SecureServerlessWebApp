resource "aws_cognito_user_pool" "user_pool" {
  name = "filevault-user-pool"

  # Enforce rigorous password policies
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  username_attributes = ["email"]

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true # <--- This forces it on the sign-up form
    mutable             = true # Allows users to change their email later if needed

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # alias_attributes         = ["email"]
  auto_verified_attributes = ["email"]

  tags = var.tags
}

resource "random_string" "domain_prefix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "secure-vault-${random_string.domain_prefix.result}"
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "filevault-frontend-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["implicit"]
  allowed_oauth_scopes                 = ["email", "openid"]
  callback_urls                        = [var.callback_url]
  logout_urls                          = [var.callback_url]
  supported_identity_providers         = ["COGNITO"]
}