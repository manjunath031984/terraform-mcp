output "ec2_instance_id" {
  description = "ID of the EC2 instance."
  value       = module.ec2.instance_id
}

output "public_ip" {
  description = "Public IPv4 address of the EC2 instance."
  value       = module.ec2.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance."
  value       = module.ec2.public_dns
}

output "ssh_command_git_bash" {
  description = "Exact Git Bash SSH command to connect to the EC2 instance."
  value       = "ssh -i ${pathexpand(var.private_key_path)} ubuntu@${module.ec2.public_ip}"
}

output "connection_instructions" {
  description = "Connection instructions and private key filename."
  value       = "Use Git Bash and run: ssh -i ${pathexpand(var.private_key_path)} ubuntu@${module.ec2.public_ip}"
}
