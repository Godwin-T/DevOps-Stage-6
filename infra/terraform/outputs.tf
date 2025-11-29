output "app_public_ip" {
  description = "Public IP address of the application server."
  value       = aws_eip.app.public_ip
}

output "app_public_dns" {
  description = "Public DNS name of the application server."
  value       = aws_instance.app.public_dns
}
