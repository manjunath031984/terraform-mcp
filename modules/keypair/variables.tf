variable "key_name" {
  description = "Name of the AWS EC2 key pair."
  type        = string
}

variable "public_key_path" {
  description = "Path to the local SSH public key file."
  type        = string
}

variable "tags" {
  description = "Tags applied to key pair resources."
  type        = map(string)
  default     = {}
}
