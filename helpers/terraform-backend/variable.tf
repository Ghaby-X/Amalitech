variable "region" {
  type = string
  default = "eu-west-1"
  description = "default region for deploying aws resource"
}

variable "bucket-prefix" {
  type = string
  default = "terraform-backend"
  description = "prefix for s3 bucket name for terraform backend"
}

variable "dynamodb-name" {
  type = string
  default = "terraform-locks"
  description = "name of dynamodb table used for terraform locking"
}
