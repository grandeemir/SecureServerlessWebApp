variable "cognito_client_id" {
  type = string
}

variable "cognito_user_pool_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "lambda_function_arn" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

variable "tags" {
  type = map(string)
}