variable "tags" {
  type = map(string)
}

variable "web_acl_id" {
  description = "The ID of the WAF Web ACL to associate with CloudFront"
  type        = string
  default     = ""
}

variable "bucket_name" {
  type = string
}

variable "cognito_user_pool_id" {
  type = string
}

variable "cognito_client_id" {
  type = string
}

variable "api_endpoint" {
  type = string
}

variable "cognito_domain" {
  type = string
}