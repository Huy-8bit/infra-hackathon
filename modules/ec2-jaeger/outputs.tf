output "instance_id" {
  description = "Jaeger instance ID"
  value       = aws_instance.jaeger.id
}

output "private_ip" {
  description = "Jaeger private IP address"
  value       = aws_instance.jaeger.private_ip
}

output "private_dns" {
  description = "Jaeger private DNS name"
  value       = aws_instance.jaeger.private_dns
}
