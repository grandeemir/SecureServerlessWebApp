variable "name" {
  description = "Name for the WAF ACL"
  type        = string
}

variable "scope" {
  description = "The scope of the WAF (REGIONAL or CLOUDFRONT)"
  type        = string
  default     = "CLOUDFRONT"
}

variable "tags" {
  description = "Tags for the resources"
  type        = map(string)
}
