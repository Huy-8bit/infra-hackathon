output "instance_id" {
  description = "ClickHouse instance ID"
  value       = aws_instance.clickhouse.id
}

output "private_ip" {
  description = "ClickHouse private IP address"
  value       = aws_instance.clickhouse.private_ip
}

output "private_dns" {
  description = "ClickHouse private DNS name"
  value       = aws_instance.clickhouse.private_dns
}
