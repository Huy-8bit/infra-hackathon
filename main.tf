terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# Security Groups
module "security_groups" {
  source = "./modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  vpc_cidr     = var.vpc_cidr
}

# ClickHouse EC2
module "clickhouse" {
  source = "./modules/ec2-clickhouse"

  project_name      = var.project_name
  environment       = var.environment
  subnet_id         = module.vpc.private_subnet_ids[0]
  security_group_id = module.security_groups.clickhouse_sg_id
  instance_type     = var.clickhouse_instance_type
  key_name          = var.key_name
}

# OpenSearch
module "opensearch" {
  source = "./modules/opensearch"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.opensearch_sg_id]
  instance_type      = var.opensearch_instance_type
  instance_count     = var.opensearch_instance_count
  master_user        = var.opensearch_master_user
  master_password    = var.opensearch_master_password
}

# MSK (Managed Kafka)
module "msk" {
  source = "./modules/msk"

  project_name       = var.project_name
  environment        = var.environment
  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.security_groups.msk_sg_id]
  kafka_version      = var.kafka_version
  instance_type      = var.kafka_instance_type
  number_of_brokers  = var.kafka_number_of_brokers
}

# Jaeger Collector EC2
module "jaeger" {
  source = "./modules/ec2-jaeger"

  project_name         = var.project_name
  environment          = var.environment
  subnet_id            = module.vpc.private_subnet_ids[0]
  security_group_id    = module.security_groups.jaeger_sg_id
  instance_type        = var.jaeger_instance_type
  key_name             = var.key_name
  clickhouse_host      = module.clickhouse.private_ip
  clickhouse_http_port = 8123
  clickhouse_tcp_port  = 9000
}

# EKS Cluster
module "eks" {
  source = "./modules/eks"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  subnet_ids              = module.vpc.private_subnet_ids
  cluster_version         = var.eks_cluster_version
  node_group_desired_size = var.eks_node_desired_size
  node_group_min_size     = var.eks_node_min_size
  node_group_max_size     = var.eks_node_max_size
  node_instance_types     = var.eks_node_instance_types
}

# RDS PostgreSQL
module "rds" {
  source = "./modules/rds"

  project_name           = var.project_name
  environment            = var.environment
  subnet_ids             = module.vpc.private_subnet_ids
  security_group_ids     = [module.security_groups.rds_sg_id]
  engine_version         = var.rds_engine_version
  instance_class         = var.rds_instance_class
  allocated_storage      = var.rds_allocated_storage
  max_allocated_storage  = var.rds_max_allocated_storage
  database_name          = var.rds_database_name
  master_username        = var.rds_master_username
  master_password        = var.rds_master_password
  backup_retention_period = var.rds_backup_retention_period
  skip_final_snapshot    = var.rds_skip_final_snapshot
  deletion_protection    = var.rds_deletion_protection
}
