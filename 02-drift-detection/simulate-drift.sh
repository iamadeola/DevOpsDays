#!/usr/bin/env bash
# simulate-drift.sh
#
# Run from the 01-provision/ directory (where the state lives):
#   bash ../02-drift-detection/simulate-drift.sh
#
# Simulates a rogue user opening SSH to the entire internet via the AWS Console.

set -euo pipefail

SG_ID=$(terraform output -raw security_group_id)
echo "Security group: $SG_ID"
echo ""
echo "==> Ingress rules BEFORE drift:"
aws ec2 describe-security-groups \
  --group-ids "$SG_ID" \
  --query 'SecurityGroups[0].IpPermissions' \
  --output table

echo ""
echo "==> Introducing drift: opening SSH (port 22) to 0.0.0.0/0..."
aws ec2 authorize-security-group-ingress \
  --group-id "$SG_ID" \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

echo ""
echo "==> Ingress rules AFTER drift:"
aws ec2 describe-security-groups \
  --group-ids "$SG_ID" \
  --query 'SecurityGroups[0].IpPermissions' \
  --output table

echo ""
echo "Drift introduced. Now run: terraform plan"
