# Lab 3 — Policy as Code
#
# Standalone configuration — independent of Lab 1's state.
# The EC2 from Lab 1 keeps running. This lab only generates a plan
# and tests it against OPA policies. Nothing is deployed.
#
# The SSH rule is intentionally set to 0.0.0.0/0 to trigger a policy failure.
# After seeing the failure, change it to your IP and re-run — policy passes.

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # No backend — this lab only runs terraform plan, never apply.
}

provider "aws" {
  region = var.region
}

# ── VPC ───────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name      = "devopsday-vpc"
    ManagedBy = "terraform"
  }
}

# ── Internet Gateway ──────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "devopsday-igw"
    ManagedBy = "terraform"
  }
}

# ── Public Subnet ─────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "devopsday-public-subnet"
    ManagedBy = "terraform"
  }
}

# ── Route Table ───────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name      = "devopsday-public-rt"
    ManagedBy = "terraform"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── Security Group — VIOLATION ────────────────────────────────────────────────
# SSH is open to 0.0.0.0/0. This is what a developer might write after the
# Lab 2 incident: "let me just make this permanent so I can always connect."
#
# `terraform validate` passes. `terraform plan` succeeds.
# But conftest will catch this before a single resource is created.

resource "aws_security_group" "ec2" {
  name        = "devopsday-ec2-sg-lab3"
  description = "Allow SSH from trusted IP only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
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

  tags = {
    Name        = "devopsday-ec2-sg-lab3"
    ManagedBy   = "terraform"
    Environment = "workshop"
  }
}

# ── EC2 Instance ──────────────────────────────────────────────────────────────

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

resource "aws_instance" "demo" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  tags = {
    Name        = "devopsday-demo-lab3"
    ManagedBy   = "terraform"
    Environment = "workshop"
  }
}
