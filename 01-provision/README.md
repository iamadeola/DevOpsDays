# Lab 1 — Provision: VPC, Subnet, and EC2 with Restricted SSH

## What Gets Created

```
aws_vpc.main  (10.0.0.0/16)
  └── aws_internet_gateway.main
  └── aws_subnet.public  (10.0.1.0/24)
        └── aws_route_table.public  (0.0.0.0/0 → IGW)
        └── aws_security_group.ec2  (SSH from YOUR_IP/32 only)  ← drift target in Lab 2
              └── aws_instance.demo  (t2.micro, Amazon Linux)
```

## Steps

### 1 — Find your public IP

```bash
curl -s https://checkip.amazonaws.com
# e.g. 203.0.113.42
```

### 2 — Create your variables file

```bash
cat > terraform.tfvars <<EOF
allowed_ssh_cidr = "203.0.113.42/32"   # replace with your actual IP
key_pair_name    = "my-keypair"         # optional — leave empty if not using SSH
EOF
```

### 3 — Deploy

```bash
terraform init
terraform apply
```

Terraform creates 8 resources: VPC, IGW, subnet, route table, route table
association, security group, AMI data source, and EC2 instance.

### 4 — Verify the security group rule

```bash
aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw security_group_id) \
  --query 'SecurityGroups[0].IpPermissions'
```

One ingress rule: SSH (port 22) from your IP only. No `0.0.0.0/0`.

### 5 — Show what Terraform recorded in state

```bash
# EC2 details
cat terraform.tfstate \
  | jq '.resources[] | select(.type == "aws_instance") | .instances[].attributes | {id, public_ip, subnet_id}'

# Security group ingress rules
cat terraform.tfstate \
  | jq '.resources[] | select(.type == "aws_security_group") | .instances[].attributes.ingress'
```

This is the **declared state**. Anything that deviates from it is drift —
which is exactly what Lab 2 demonstrates.

---

**Keep this instance running. Labs 2 and 3 operate on it.**
