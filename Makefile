.PHONY: help init plan apply destroy clean fmt validate

# Variables
TERRAFORM := terraform
AWS_REGION ?= ap-southeast-1

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform
	@echo "Initializing Terraform..."
	$(TERRAFORM) init

plan: ## Run Terraform plan
	@echo "Running Terraform plan..."
	$(TERRAFORM) plan

apply: ## Apply Terraform changes
	@echo "Applying Terraform changes..."
	$(TERRAFORM) apply

apply-auto: ## Apply Terraform changes without confirmation
	@echo "Auto-applying Terraform changes..."
	$(TERRAFORM) apply -auto-approve

destroy: ## Destroy all resources
	@echo "WARNING: This will destroy all resources!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(TERRAFORM) destroy; \
	fi

destroy-auto: ## Destroy all resources without confirmation
	@echo "Auto-destroying all resources..."
	$(TERRAFORM) destroy -auto-approve

clean: ## Clean Terraform files
	@echo "Cleaning Terraform files..."
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate*
	rm -f *tfplan*

fmt: ## Format Terraform files
	@echo "Formatting Terraform files..."
	$(TERRAFORM) fmt -recursive

validate: ## Validate Terraform configuration
	@echo "Validating Terraform configuration..."
	$(TERRAFORM) validate

output: ## Show Terraform outputs
	@echo "Terraform outputs:"
	$(TERRAFORM) output

output-json: ## Show Terraform outputs in JSON format
	@echo "Terraform outputs (JSON):"
	$(TERRAFORM) output -json

refresh: ## Refresh Terraform state
	@echo "Refreshing Terraform state..."
	$(TERRAFORM) refresh

# EKS specific targets
eks-config: ## Configure kubectl for EKS
	@echo "Configuring kubectl for EKS..."
	@CLUSTER_NAME=$$($(TERRAFORM) output -raw eks_cluster_id 2>/dev/null); \
	if [ -n "$$CLUSTER_NAME" ]; then \
		aws eks update-kubeconfig --region $(AWS_REGION) --name $$CLUSTER_NAME; \
		echo "kubectl configured for cluster: $$CLUSTER_NAME"; \
	else \
		echo "Error: EKS cluster not found. Run 'make apply' first."; \
	fi

eks-nodes: ## Show EKS nodes
	@echo "EKS nodes:"
	@kubectl get nodes

# Service connection info
clickhouse-ip: ## Get ClickHouse private IP
	@$(TERRAFORM) output -raw clickhouse_private_ip

opensearch-endpoint: ## Get OpenSearch endpoint
	@$(TERRAFORM) output -raw opensearch_endpoint

kafka-brokers: ## Get Kafka bootstrap brokers
	@$(TERRAFORM) output -raw msk_bootstrap_brokers

jaeger-ip: ## Get Jaeger private IP
	@$(TERRAFORM) output -raw jaeger_private_ip

# Connection helpers
connect-clickhouse: ## Connect to ClickHouse via Session Manager
	@INSTANCE_ID=$$($(TERRAFORM) output -raw clickhouse_instance_id 2>/dev/null); \
	if [ -n "$$INSTANCE_ID" ]; then \
		echo "Connecting to ClickHouse instance: $$INSTANCE_ID"; \
		aws ssm start-session --target $$INSTANCE_ID; \
	else \
		echo "Error: ClickHouse instance not found."; \
	fi

connect-jaeger: ## Connect to Jaeger via Session Manager
	@INSTANCE_ID=$$($(TERRAFORM) output -raw jaeger_instance_id 2>/dev/null); \
	if [ -n "$$INSTANCE_ID" ]; then \
		echo "Connecting to Jaeger instance: $$INSTANCE_ID"; \
		aws ssm start-session --target $$INSTANCE_ID; \
	else \
		echo "Error: Jaeger instance not found."; \
	fi

port-forward-jaeger: ## Port forward Jaeger UI (16686)
	@INSTANCE_ID=$$($(TERRAFORM) output -raw jaeger_instance_id 2>/dev/null); \
	if [ -n "$$INSTANCE_ID" ]; then \
		echo "Port forwarding Jaeger UI on http://localhost:16686"; \
		aws ssm start-session --target $$INSTANCE_ID \
			--document-name AWS-StartPortForwardingSession \
			--parameters '{"portNumber":["16686"],"localPortNumber":["16686"]}'; \
	else \
		echo "Error: Jaeger instance not found."; \
	fi

# Validation and checks
check-tfvars: ## Check if terraform.tfvars exists
	@if [ ! -f terraform.tfvars ]; then \
		echo "Error: terraform.tfvars not found!"; \
		echo "Please copy terraform.tfvars.example to terraform.tfvars and configure it."; \
		exit 1; \
	fi

check-aws: ## Check AWS credentials
	@echo "Checking AWS credentials..."
	@aws sts get-caller-identity

check-all: check-tfvars check-aws ## Run all checks
	@echo "All checks passed!"

# Development workflow
dev-init: check-all init ## Initialize for development
	@echo "Development environment initialized!"

dev-deploy: dev-init fmt validate plan apply ## Full development deployment

# Backup state
backup-state: ## Backup Terraform state
	@echo "Backing up Terraform state..."
	@mkdir -p backups
	@cp terraform.tfstate backups/terraform.tfstate.$$(date +%Y%m%d-%H%M%S)
	@echo "State backed up to backups/"

# Documentation
docs: ## Generate documentation
	@echo "Generating Terraform documentation..."
	@which terraform-docs > /dev/null 2>&1 || (echo "terraform-docs not found. Install from https://terraform-docs.io/" && exit 1)
	@terraform-docs markdown table --output-file MODULES.md .

# Cost estimation (requires infracost)
cost: ## Estimate infrastructure cost
	@echo "Estimating infrastructure cost..."
	@which infracost > /dev/null 2>&1 || (echo "infracost not found. Install from https://www.infracost.io/" && exit 1)
	@infracost breakdown --path .
