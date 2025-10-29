# AWS Configuration
aws_region   = "ap-southeast-1"
project_name = "observability-platform"
environment  = "dev"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# ClickHouse Configuration
clickhouse_instance_type = "t3.large"

# OpenSearch Configuration
opensearch_instance_type  = "t3.medium.search"
opensearch_instance_count = 3
opensearch_master_user    = "admin"
opensearch_master_password = "YourSecurePassword123!"

# Kafka (MSK) Configuration
kafka_version           = "3.6.0"
kafka_instance_type     = "kafka.t3.small"
kafka_number_of_brokers = 3

# Jaeger Configuration
jaeger_instance_type = "t3.medium"

# EKS Configuration
eks_cluster_version     = "1.28"
eks_node_desired_size   = 3
eks_node_min_size       = 2
eks_node_max_size       = 5
eks_node_instance_types = ["t3.large"]

# SSH Key (Create this key in AWS first)
key_name = "KeyPair"
