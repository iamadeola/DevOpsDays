# CORRECT PATTERN
#
# Same EC2 as Lab 1. The app secret is stored in AWS SSM Parameter Store.
# Terraform manages the parameter's existence — never its value.
# The EC2 fetches the secret at runtime using the AWS CLI / SDK.
# The state file contains only an ARN, never the secret itself.

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ── SSM Parameter (Terraform manages the slot, not the value) ─────────────────

resource "aws_ssm_parameter" "app_secret" {
  name        = "/devopsday/demo/app-secret"
  description = "Application secret for the demo EC2"
  type        = "SecureString"  # encrypted at rest with KMS
  value       = "PLACEHOLDER"   # set the real value outside Terraform:
                                 # aws ssm put-parameter --name /devopsday/demo/app-secret \
                                 #   --value "real-secret" --type SecureString --overwrite

  lifecycle {
    ignore_changes = [value]  # Terraform won't overwrite the real value on re-apply
  }

  tags = {
    ManagedBy = "terraform"
  }
}

# ── IAM policy — EC2 can read only its own parameter ─────────────────────────

resource "aws_iam_role" "ec2" {
  name = "devopsday-demo-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ssm_read" {
  name = "ssm-read-app-secret"
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameter"]
      Resource = aws_ssm_parameter.app_secret.arn
    }]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "devopsday-demo-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ── EC2 — user_data fetches the secret at boot via AWS CLI ────────────────────

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "ec2" {
  name        = "devopsday-demo-good-sg"
  description = "Demo SG"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "demo" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # The secret name (not value) is passed in. The instance fetches it at runtime.
  user_data = <<-EOF
    #!/bin/bash
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
    APP_SECRET=$(aws ssm get-parameter \
      --name "${aws_ssm_parameter.app_secret.name}" \
      --with-decryption \
      --query Parameter.Value \
      --output text \
      --region "$REGION")
    echo "APP_SECRET=$APP_SECRET" >> /etc/environment
  EOF

  tags = {
    Name = "devopsday-demo-good"
  }
}
