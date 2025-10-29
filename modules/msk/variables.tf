variable "project_name" {
  description = "Project name for tagging resources"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for MSK brokers"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "kafka_version" {
  description = "Kafka version"
  type        = string
  default     = "3.6.0"
}

variable "instance_type" {
  description = "Instance type for Kafka brokers"
  type        = string
  default     = "kafka.t3.small"
}

variable "number_of_brokers" {
  description = "Number of Kafka brokers (must be multiple of AZs)"
  type        = number
  default     = 3

  validation {
    condition     = var.number_of_brokers >= 2
    error_message = "Number of brokers must be at least 2"
  }
}
