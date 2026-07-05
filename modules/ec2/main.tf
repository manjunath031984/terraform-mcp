resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = var.security_group_ids
  user_data                   = file(var.user_data_path)
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted   = true
    volume_size = 30
    volume_type = "gp3"

    tags = merge(var.tags, {
      Name = "${var.name}-root"
    })
  }

  tags = merge(var.tags, {
    Name = var.name
  })
}
