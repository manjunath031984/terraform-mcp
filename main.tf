data "aws_vpc" "default" {
  default = true
}

# Terraform discovers the operator's public IP during planning and uses it for SSH access only.
data "http" "current_public_ip" {
  url = "https://checkip.amazonaws.com"

  request_headers = {
    Accept = "text/plain"
  }
}

locals {
  current_public_ip = chomp(data.http.current_public_ip.response_body)

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "keypair" {
  source = "./modules/keypair"

  key_name        = "${var.project_name}-${var.environment}-key"
  public_key_path = var.public_key_path
  tags            = local.common_tags
}

module "security_group" {
  source = "./modules/security-group"

  name        = "${var.project_name}-${var.environment}-sg"
  description = "Allow SSH from current public IP and web traffic from the internet."
  vpc_id      = data.aws_vpc.default.id
  ssh_cidr    = "${local.current_public_ip}/32"
  tags        = local.common_tags
}

module "ec2" {
  source = "./modules/ec2"

  name               = "${var.project_name}-${var.environment}-instance"
  ami_id             = var.ami_id
  instance_type      = var.instance_type
  key_name           = module.keypair.key_name
  security_group_ids = [module.security_group.security_group_id]
  user_data_path     = "${path.module}/userdata.sh"
  tags               = local.common_tags
}
