output "domain_arn" {
  description = "ARN of the OpenSearch domain"
  value       = aws_opensearch_domain.main.arn
}

output "domain_id" {
  description = "ID of the OpenSearch domain"
  value       = aws_opensearch_domain.main.domain_id
}

output "endpoint" {
  description = "Domain-specific endpoint for the OpenSearch domain"
  value       = "https://${aws_opensearch_domain.main.endpoint}"
}

output "dashboard_endpoint" {
  description = "Domain-specific endpoint for OpenSearch Dashboards"
  value       = "https://${aws_opensearch_domain.main.dashboard_endpoint}"
}
