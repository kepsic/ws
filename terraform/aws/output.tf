# terraform output -raw ssh_private_key
output "tls_private_key" {
  value     = tls_private_key.emonstack_ssh.private_key_pem
  sensitive = true
}

# terraform output -raw ssh_public_key
output "ssh_public_key" {
  value = tls_private_key.emonstack_ssh.public_key_openssh
}

# terraform output -raw public_ip
output "public_ip" {
  value = aws_instance.emonstack_web_instance.public_dns
}
