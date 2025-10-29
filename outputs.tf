output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "clickhouse_private_ip" {
  description = "ClickHouse private IP address"
  value       = module.clickhouse.private_ip
}

output "clickhouse_instance_id" {
  description = "ClickHouse EC2 instance ID"
  value       = module.clickhouse.instance_id
}

output "opensearch_endpoint" {
  description = "OpenSearch domain endpoint"
  value       = module.opensearch.endpoint
}

output "opensearch_dashboard_endpoint" {
  description = "OpenSearch Dashboards endpoint"
  value       = module.opensearch.dashboard_endpoint
}

output "opensearch_domain_arn" {
  description = "OpenSearch domain ARN"
  value       = module.opensearch.domain_arn
}

output "msk_cluster_arn" {
  description = "MSK cluster ARN"
  value       = module.msk.cluster_arn
}

output "msk_bootstrap_brokers" {
  description = "MSK bootstrap brokers"
  value       = module.msk.bootstrap_brokers
}

output "msk_zookeeper_connect_string" {
  description = "MSK Zookeeper connection string"
  value       = module.msk.zookeeper_connect_string
}

output "jaeger_private_ip" {
  description = "Jaeger Collector private IP address"
  value       = module.jaeger.private_ip
}

output "jaeger_instance_id" {
  description = "Jaeger EC2 instance ID"
  value       = module.jaeger.instance_id
}

output "eks_cluster_id" {
  description = "EKS cluster ID"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_id}"
}

output "rds_instance_endpoint" {
  description = "RDS PostgreSQL instance endpoint"
  value       = module.rds.db_instance_endpoint
}

output "rds_instance_address" {
  description = "RDS PostgreSQL instance address"
  value       = module.rds.db_instance_address
}

output "rds_instance_port" {
  description = "RDS PostgreSQL instance port"
  value       = module.rds.db_instance_port
}

output "rds_database_name" {
  description = "RDS PostgreSQL database name"
  value       = module.rds.db_name
}

output "rds_instance_arn" {
  description = "RDS PostgreSQL instance ARN"
  value       = module.rds.db_instance_arn
}
