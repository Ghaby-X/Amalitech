variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "AWS region to register the key pair in"
}

variable "key_name" {
  type        = string
  default     = "lab-public-key.pem"
  description = "Name registered for the AWS key pair"
}

variable "private_key_path" {
  type        = string
  default     = "./lab-private-key.pem"
  description = "Local path to write the generated private key to"
}
