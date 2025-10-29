# ClickHouse Security Group
resource "aws_security_group" "clickhouse" {
  name_prefix = "${var.project_name}-${var.environment}-clickhouse-"
  description = "Security group for ClickHouse server"
  vpc_id      = var.vpc_id

  # HTTP Interface (8123)
  ingress {
    from_port   = 8123
    to_port     = 8123
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "ClickHouse HTTP interface"
  }

  # Native Protocol (9000)
  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "ClickHouse native protocol"
  }

  # Interserver HTTP (9009) - for replication
  ingress {
    from_port   = 9009
    to_port     = 9009
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "ClickHouse interserver HTTP"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-clickhouse-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# OpenSearch Security Group
resource "aws_security_group" "opensearch" {
  name_prefix = "${var.project_name}-${var.environment}-opensearch-"
  description = "Security group for OpenSearch"
  vpc_id      = var.vpc_id

  # HTTPS (443) - OpenSearch endpoint
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "OpenSearch HTTPS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-opensearch-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# MSK (Kafka) Security Group
resource "aws_security_group" "msk" {
  name_prefix = "${var.project_name}-${var.environment}-msk-"
  description = "Security group for MSK Kafka cluster"
  vpc_id      = var.vpc_id

  # Plaintext (9092)
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Kafka plaintext"
  }

  # TLS (9094)
  ingress {
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Kafka TLS"
  }

  # SASL/SCRAM (9096)
  ingress {
    from_port   = 9096
    to_port     = 9096
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Kafka SASL/SCRAM"
  }

  # IAM (9098)
  ingress {
    from_port   = 9098
    to_port     = 9098
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Kafka IAM"
  }

  # Zookeeper (2181)
  ingress {
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Zookeeper"
  }

  # Zookeeper TLS (2182)
  ingress {
    from_port   = 2182
    to_port     = 2182
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Zookeeper TLS"
  }

  # JMX Exporter (11001)
  ingress {
    from_port   = 11001
    to_port     = 11001
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "JMX Exporter"
  }

  # Node Exporter (11002)
  ingress {
    from_port   = 11002
    to_port     = 11002
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Node Exporter"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-msk-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Jaeger Collector Security Group
resource "aws_security_group" "jaeger" {
  name_prefix = "${var.project_name}-${var.environment}-jaeger-"
  description = "Security group for Jaeger Collector"
  vpc_id      = var.vpc_id

  # Jaeger Collector gRPC (14250)
  ingress {
    from_port   = 14250
    to_port     = 14250
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Jaeger Collector gRPC"
  }

  # Jaeger Collector HTTP (14268)
  ingress {
    from_port   = 14268
    to_port     = 14268
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Jaeger Collector HTTP"
  }

  # Jaeger Admin port (14269)
  ingress {
    from_port   = 14269
    to_port     = 14269
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Jaeger Admin port"
  }

  # Zipkin compatible endpoint (9411)
  ingress {
    from_port   = 9411
    to_port     = 9411
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Zipkin compatible endpoint"
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-jaeger-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# RDS PostgreSQL Security Group
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = var.vpc_id

  # PostgreSQL (5432)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "PostgreSQL access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# EKS Cluster Security Group (Additional rules)
resource "aws_security_group" "eks_additional" {
  name_prefix = "${var.project_name}-${var.environment}-eks-additional-"
  description = "Additional security group for EKS cluster communication"
  vpc_id      = var.vpc_id

  # Allow pods to communicate with Jaeger
  egress {
    from_port       = 14250
    to_port         = 14250
    protocol        = "tcp"
    security_groups = [aws_security_group.jaeger.id]
    description     = "Allow EKS pods to send traces to Jaeger"
  }

  # Allow pods to communicate with ClickHouse
  egress {
    from_port       = 8123
    to_port         = 8123
    protocol        = "tcp"
    security_groups = [aws_security_group.clickhouse.id]
    description     = "Allow EKS pods to connect to ClickHouse HTTP"
  }

  egress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.clickhouse.id]
    description     = "Allow EKS pods to connect to ClickHouse native"
  }

  # Allow pods to communicate with OpenSearch
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.opensearch.id]
    description     = "Allow EKS pods to connect to OpenSearch"
  }

  # Allow pods to communicate with MSK
  egress {
    from_port       = 9092
    to_port         = 9098
    protocol        = "tcp"
    security_groups = [aws_security_group.msk.id]
    description     = "Allow EKS pods to connect to Kafka"
  }

  # Allow pods to communicate with RDS
  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.rds.id]
    description     = "Allow EKS pods to connect to PostgreSQL"
  }

  # General internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-eks-additional-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}
