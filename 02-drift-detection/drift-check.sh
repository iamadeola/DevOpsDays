#!/usr/bin/env bash
# drift-check.sh
#
# Run from the 01-provision/ directory (where the state lives):
#   bash ../02-drift-detection/drift-check.sh
#
# Detects any drift between Terraform state and real AWS infrastructure.
# Exit codes: 0 = clean, 2 = drift detected.

set -euo pipefail

echo "==> Checking for infrastructure drift..."

if terraform plan -detailed-exitcode -refresh=true -input=false -no-color -out drift.plan 2>&1; then
  echo ""
  echo "✓ No drift detected."
  exit 0
fi

EXIT_CODE=$?

if [ "$EXIT_CODE" -eq 2 ]; then
  echo ""
  echo "================================================================"
  echo "  DRIFT DETECTED"
  echo "================================================================"
  terraform show -no-color drift.plan
  echo "================================================================"
  echo ""
  echo "To revert:  terraform apply drift.plan"
  echo ""
  exit 2
fi

exit "$EXIT_CODE"
