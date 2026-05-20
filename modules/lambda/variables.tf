variable "tags" {
  type = map(string)
}

variable "table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "table_arn" {
  description = "The ARN of the DynamoDB table"
  type        = string
}

variable "storage_bucket_name" {
  description = "The name of the S3 storage bucket"
  type        = string
}

variable "storage_bucket_arn" {
  description = "The ARN of the S3 storage bucket"
  type        = string
}