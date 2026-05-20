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

variable "enable_waf" {
  description = "API Gateway'e WAF baglanacak mi?"
  type        = bool
  default     = false
}

variable "web_acl_arn" {
  description = "The ARN of the WAF Web ACL to associate with API Gateway"
  type        = string
  default     = ""
}