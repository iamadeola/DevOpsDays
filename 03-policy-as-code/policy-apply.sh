#!/usr/bin/env bash
# policy-apply.sh
#
# Drop-in replacement for `terraform apply`.
# Runs conftest policy checks against the plan — blocks deployment if any policy fails.
#
# Usage:
#   bash policy-apply.sh

set -euo pipefail

POLICY_DIR="$(dirname "$0")/policies"

echo "==> Generating plan..."
terraform plan -out plan.bin

echo ""
echo "==> Exporting plan to JSON..."
terraform show -json plan.bin > plan.json

echo ""
echo "==> Running policy checks..."
if ! conftest test plan.json --policy "$POLICY_DIR" --all-namespaces; then
  echo ""
  echo "================================================================"
  echo "  POLICY VIOLATION — deployment blocked"
  echo "  Fix the violations above before applying."
  echo "================================================================"
  rm -f plan.bin plan.json
  exit 1
fi

echo ""
echo "================================================================"
echo "  All policies passed. Proceeding with apply..."
echo "================================================================"
echo ""
terraform apply plan.bin

rm -f plan.bin plan.json
