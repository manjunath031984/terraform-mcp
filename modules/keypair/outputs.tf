output "key_name" {
  description = "Name of the created AWS EC2 key pair."
  value       = aws_key_pair.this.key_name
}

output "key_pair_id" {
  description = "ID of the created AWS EC2 key pair."
  value       = aws_key_pair.this.id
}

output "fingerprint" {
  description = "Fingerprint of the created AWS EC2 key pair."
  value       = aws_key_pair.this.fingerprint
}
