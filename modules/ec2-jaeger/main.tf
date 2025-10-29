# Get latest Ubuntu 22.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for Jaeger EC2
resource "aws_iam_role" "jaeger" {
  name = "${var.project_name}-${var.environment}-jaeger-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-jaeger-role"
  }
}

# Attach SSM policy for Session Manager access
resource "aws_iam_role_policy_attachment" "jaeger_ssm" {
  role       = aws_iam_role.jaeger.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch policy for logs
resource "aws_iam_role_policy_attachment" "jaeger_cloudwatch" {
  role       = aws_iam_role.jaeger.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "jaeger" {
  name = "${var.project_name}-${var.environment}-jaeger-profile"
  role = aws_iam_role.jaeger.name

  tags = {
    Name = "${var.project_name}-${var.environment}-jaeger-profile"
  }
}

# Jaeger EC2 Instance
resource "aws_instance" "jaeger" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.jaeger.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    clickhouse_host      = var.clickhouse_host
    clickhouse_http_port = var.clickhouse_http_port
    clickhouse_tcp_port  = var.clickhouse_tcp_port
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-jaeger"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}
