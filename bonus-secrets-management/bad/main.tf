# !! ANTI-PATTERN — DO NOT USE IN PRODUCTION !!
#
# Same EC2 as Lab 1, but a developer has added an app secret directly
# into user_data as a shell variable. It ends up in terraform.tfstate
# in plaintext — readable by anyone with state access.

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
  region = "eu-central-1"
}

variable "app_secret" {
  description = "Application secret — ANTI-PATTERN: ends up in state as plaintext"
  type        = string
  sensitive   = true  # hides value in CLI output ONLY — not in the state file
}

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
  name        = "devopsday-demo-bad-sg"
  description = "Demo SG"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

  # BAD: the secret is baked into user_data.
  # Terraform stores user_data verbatim in state — in plaintext.
  user_data = <<-EOF
    #!/bin/bash
    export APP_SECRET="${var.app_secret}"
    echo "APP_SECRET=$APP_SECRET" >> /etc/environment
  EOF

  tags = {
    Name = "devopsday-demo-bad"
  }
}

# After apply, run this to prove the secret is in state:
#
#   cat terraform.tfstate \
#     | jq -r '.resources[] | select(.type=="aws_instance") | .instances[].attributes.user_data' \
#     | base64 -d
#
# The APP_SECRET value will be visible in plain text.
