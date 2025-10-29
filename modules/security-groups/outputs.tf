output "clickhouse_sg_id" {
  description = "ClickHouse security group ID"
  value       = aws_security_group.clickhouse.id
}

output "opensearch_sg_id" {
  description = "OpenSearch security group ID"
  value       = aws_security_group.opensearch.id
}

output "msk_sg_id" {
  description = "MSK security group ID"
  value       = aws_security_group.msk.id
}

output "jaeger_sg_id" {
  description = "Jaeger security group ID"
  value       = aws_security_group.jaeger.id
}

output "rds_sg_id" {
  description = "RDS security group ID"
  value       = aws_security_group.rds.id
}

output "eks_additional_sg_id" {
  description = "EKS additional security group ID"
  value       = aws_security_group.eks_additional.id
}
