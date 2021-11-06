# terraform output -raw ssh_private_key
output "tls_private_key" {
  value     = tls_private_key.emon_tallinn_ssh.private_key_pem
  sensitive = true
}

# terraform output -raw ssh_private_key
output "ssh_public_key" {
  value = tls_private_key.emon_tallinn_ssh.public_key_openssh
}

# terraform output -raw emon_tallinn_public_ip
output "public_ip" {
  value = azurerm_public_ip.emon_tf_public_ip.ip_address
}