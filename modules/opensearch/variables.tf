variable "project_name" {
  description = "Project name for tagging resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for OpenSearch domain"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type for OpenSearch nodes"
  type        = string
  default     = "t3.medium.search"
}

variable "instance_count" {
  description = "Number of instances in the cluster"
  type        = number
  default     = 3
}

variable "master_user" {
  description = "Master username for OpenSearch"
  type        = string
}

variable "master_password" {
  description = "Master password for OpenSearch"
  type        = string
  sensitive   = true
}
