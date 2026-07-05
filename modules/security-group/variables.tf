variable "name" {
  description = "Name of the security group."
  type        = string
}

variable "description" {
  description = "Description of the security group."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the security group will be created."
  type        = string
}

variable "ssh_cidr" {
  description = "Single CIDR block allowed to connect over SSH."
  type        = string
}

variable "tags" {
  description = "Tags applied to security group resources."
  type        = map(string)
  default     = {}
}
