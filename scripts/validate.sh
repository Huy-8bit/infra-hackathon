#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================"
echo "Terraform Configuration Validator"
echo "================================"
echo ""

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

# Track errors
ERRORS=0

# Check if running in correct directory
if [ ! -f "main.tf" ]; then
    print_error "main.tf not found. Please run this script from the infra directory."
    exit 1
fi

print_success "Running in correct directory"

# Check Terraform installation
echo ""
echo "Checking prerequisites..."
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed"
    ERRORS=$((ERRORS + 1))
else
    TF_VERSION=$(terraform version -json | grep -o '"version":"[^"]*' | cut -d'"' -f4)
    print_success "Terraform installed (version: $TF_VERSION)"
fi

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    ERRORS=$((ERRORS + 1))
else
    AWS_VERSION=$(aws --version 2>&1 | cut -d' ' -f1)
    print_success "AWS CLI installed ($AWS_VERSION)"
fi

# Check AWS credentials
echo ""
echo "Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
    print_success "AWS credentials valid"
    echo "  Account: $ACCOUNT_ID"
    echo "  Identity: $USER_ARN"
else
    print_error "AWS credentials not configured or invalid"
    ERRORS=$((ERRORS + 1))
fi

# Check terraform.tfvars
echo ""
echo "Checking configuration files..."
if [ ! -f "terraform.tfvars" ]; then
    print_error "terraform.tfvars not found"
    print_warning "Copy terraform.tfvars.example to terraform.tfvars and configure it"
    ERRORS=$((ERRORS + 1))
else
    print_success "terraform.tfvars exists"

    # Check required variables
    echo ""
    echo "Validating required variables..."

    # Check key_name
    if grep -q 'key_name.*=.*".*"' terraform.tfvars; then
        KEY_NAME=$(grep 'key_name' terraform.tfvars | cut -d'"' -f2)
        if [ "$KEY_NAME" = "your-ssh-key-name" ]; then
            print_error "key_name is set to default value. Please update it."
            ERRORS=$((ERRORS + 1))
        else
            print_success "key_name is configured: $KEY_NAME"

            # Verify key exists in AWS
            if aws ec2 describe-key-pairs --key-names "$KEY_NAME" &> /dev/null; then
                print_success "SSH key exists in AWS"
            else
                print_error "SSH key '$KEY_NAME' not found in AWS"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    else
        print_error "key_name not configured in terraform.tfvars"
        ERRORS=$((ERRORS + 1))
    fi

    # Check opensearch_master_password
    if grep -q 'opensearch_master_password.*=.*".*"' terraform.tfvars; then
        PASSWORD=$(grep 'opensearch_master_password' terraform.tfvars | cut -d'"' -f2)
        if [ "$PASSWORD" = "YourSecurePassword123!" ]; then
            print_warning "opensearch_master_password is set to example value. Consider changing it."
        else
            # Check password strength
            if [ ${#PASSWORD} -lt 8 ]; then
                print_error "opensearch_master_password is too short (minimum 8 characters)"
                ERRORS=$((ERRORS + 1))
            elif [[ ! "$PASSWORD" =~ [A-Z] ]] || [[ ! "$PASSWORD" =~ [a-z] ]] || [[ ! "$PASSWORD" =~ [0-9] ]]; then
                print_warning "opensearch_master_password should contain uppercase, lowercase, and numbers"
            else
                print_success "opensearch_master_password is configured"
            fi
        fi
    else
        print_error "opensearch_master_password not configured in terraform.tfvars"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check Terraform formatting
echo ""
echo "Checking Terraform formatting..."
if terraform fmt -check -recursive &> /dev/null; then
    print_success "All Terraform files are properly formatted"
else
    print_warning "Some Terraform files need formatting. Run 'terraform fmt -recursive'"
fi

# Validate Terraform configuration
echo ""
echo "Validating Terraform configuration..."
if [ ! -d ".terraform" ]; then
    print_warning "Terraform not initialized. Run 'terraform init' first."
else
    if terraform validate &> /dev/null; then
        print_success "Terraform configuration is valid"
    else
        print_error "Terraform configuration is invalid"
        terraform validate
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check AWS quotas (service limits)
echo ""
echo "Checking AWS service quotas..."

# VPCs
VPC_QUOTA=$(aws service-quotas get-service-quota --service-code vpc --quota-code L-F678F1CE --query 'Quota.Value' --output text 2>/dev/null || echo "Unknown")
VPC_USAGE=$(aws ec2 describe-vpcs --query 'length(Vpcs)' --output text 2>/dev/null || echo "0")
if [ "$VPC_QUOTA" != "Unknown" ]; then
    print_success "VPC quota: $VPC_USAGE/$VPC_QUOTA"
    if [ "$VPC_USAGE" -ge "$VPC_QUOTA" ]; then
        print_error "VPC quota exceeded"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Elastic IPs
EIP_QUOTA=$(aws service-quotas get-service-quota --service-code ec2 --quota-code L-0263D0A3 --query 'Quota.Value' --output text 2>/dev/null || echo "Unknown")
if [ "$EIP_QUOTA" != "Unknown" ]; then
    print_success "Elastic IP quota: $EIP_QUOTA (need 3 for NAT Gateways)"
    if [ $(echo "$EIP_QUOTA < 3" | bc -l) -eq 1 ]; then
        print_error "Not enough Elastic IP quota (need at least 3)"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Estimate costs
echo ""
echo "================================"
echo "Estimated Monthly Costs (Development):"
echo "================================"
echo "VPC & Networking:"
echo "  - NAT Gateways (3x):        ~\$100"
echo "  - Data Transfer:            ~\$10-50"
echo ""
echo "Compute:"
echo "  - ClickHouse EC2:           ~\$60"
echo "  - Jaeger EC2:               ~\$30"
echo "  - EKS Control Plane:        \$72"
echo "  - EKS Nodes (3x t3.large):  ~\$180"
echo ""
echo "Managed Services:"
echo "  - OpenSearch (3 nodes):     ~\$105"
echo "  - MSK (3 brokers):          ~\$180"
echo ""
echo "Storage:"
echo "  - EBS Volumes:              ~\$20"
echo ""
echo "Total Estimate:               ~\$650-700/month"
echo ""
print_warning "This is an estimate. Actual costs may vary based on usage."

# Summary
echo ""
echo "================================"
echo "Validation Summary"
echo "================================"

if [ $ERRORS -eq 0 ]; then
    print_success "All checks passed! Ready to deploy."
    echo ""
    echo "Next steps:"
    echo "  1. Review the configuration: terraform plan"
    echo "  2. Deploy the infrastructure: terraform apply"
    echo "  3. Configure kubectl: make eks-config"
    exit 0
else
    print_error "Found $ERRORS error(s). Please fix them before deploying."
    echo ""
    echo "Common fixes:"
    echo "  - Install missing tools (Terraform, AWS CLI)"
    echo "  - Configure AWS credentials: aws configure"
    echo "  - Create terraform.tfvars from example file"
    echo "  - Create SSH key pair in AWS Console"
    exit 1
fi
