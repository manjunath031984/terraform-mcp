data "aws_vpc" "default" {
  default = true
}

locals {
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
  ssh_cidr    = var.ssh_cidr
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
