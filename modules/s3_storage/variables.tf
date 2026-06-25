variable "bucket_name" {
  description = "The name of the storage bucket"
  type        = string
}

variable "tags" {
  type = map(string)
}
