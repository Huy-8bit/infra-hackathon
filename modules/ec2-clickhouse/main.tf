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

# IAM Role for ClickHouse EC2
resource "aws_iam_role" "clickhouse" {
  name = "${var.project_name}-${var.environment}-clickhouse-role"

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
    Name = "${var.project_name}-${var.environment}-clickhouse-role"
  }
}

# Attach SSM policy for Session Manager access
resource "aws_iam_role_policy_attachment" "clickhouse_ssm" {
  role       = aws_iam_role.clickhouse.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch policy for logs
resource "aws_iam_role_policy_attachment" "clickhouse_cloudwatch" {
  role       = aws_iam_role.clickhouse.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "clickhouse" {
  name = "${var.project_name}-${var.environment}-clickhouse-profile"
  role = aws_iam_role.clickhouse.name

  tags = {
    Name = "${var.project_name}-${var.environment}-clickhouse-profile"
  }
}

# EBS Volume for ClickHouse data
resource "aws_ebs_volume" "clickhouse_data" {
  availability_zone = data.aws_subnet.selected.availability_zone
  size              = 100
  type              = "gp3"
  iops              = 3000
  throughput        = 125
  encrypted         = true

  tags = {
    Name = "${var.project_name}-${var.environment}-clickhouse-data"
  }
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

# ClickHouse EC2 Instance
resource "aws_instance" "clickhouse" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.clickhouse.name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    device_name = "/dev/xvdf"
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-clickhouse"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

# Attach EBS volume to instance
resource "aws_volume_attachment" "clickhouse_data" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.clickhouse_data.id
  instance_id = aws_instance.clickhouse.id
}
