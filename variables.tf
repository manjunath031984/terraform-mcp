variable "aws_region" {
  description = "AWS Region where the EC2 instance will be provisioned."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging."
  type        = string
  default     = "terraform-ec2"
}

variable "environment" {
  description = "Deployment environment tag value."
  type        = string
  default     = "prod"
}

variable "ami_id" {
  description = "Ubuntu Server 22.04 with SQL Server 2022 Standard Edition AMI ID."
  type        = string
  default     = "ami-051e483428ae60e7d"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "ssh_cidr" {
  description = "CIDR block allowed to connect over SSH. Use your current public IP with a /32 suffix."
  type        = string
}

variable "public_key_path" {
  description = "Local SSH public key file path used to create the AWS EC2 key pair."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "Local SSH private key file path used in the generated Git Bash SSH command."
  type        = string
  default     = "~/.ssh/id_rsa"
}
