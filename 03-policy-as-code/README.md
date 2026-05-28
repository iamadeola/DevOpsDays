# Lab 3 — Policy as Code

> **The EC2 from Lab 1 keeps running throughout this lab.**
> Lab 3 demonstrates how OPA policies block a non-compliant deployment before
> any resource is created or changed.

## The Scenario

After the Lab 2 incident, a developer decides to make the `0.0.0.0/0` SSH
rule permanent in code so they can always connect from anywhere. They update
their config and open a PR.

`terraform validate` passes. `terraform plan` succeeds.

But the OPA policy check **blocks the PR before anything reaches production**.

## What is Policy as Code?

```
bash policy-apply.sh
  └─ terraform plan
  └─ conftest test plan.json  ← FAIL: deployment blocked
                              ← PASS: terraform apply proceeds
```

Instead of relying on a human reviewer to catch the bad SSH rule, a
machine-readable policy runs automatically on every PR. It lives in version
control. It can't be skipped.

Policies enforced in this lab:

| Policy | Rule |
|--------|------|
| `SG-001` | No SSH/RDP open to `0.0.0.0/0` or `::/0` |
| `SG-003` | SSH source must be a single host (`/32` for IPv4, `/128` for IPv6) |
| `TAG-001` | All resources must have `Environment` and `ManagedBy` tags |

---

## Prerequisites

### Install Conftest

```bash
# macOS
brew install conftest

# Windows (ARM64) — download directly from GitHub releases
# Find the latest Windows arm64 zip at:
# https://github.com/open-policy-agent/conftest/releases/latest
# Extract and add to your PATH

# Windows (x86_64)
choco install conftest

# Linux
curl -Lo conftest.tar.gz \
  https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_0.46.0_Linux_x86_64.tar.gz
tar xzf conftest.tar.gz && sudo mv conftest /usr/local/bin/
```

### Get your public IP

You will need your public IP in CIDR notation to fix the violation in Step 2.

```bash
# macOS / Linux
curl -s https://checkip.amazonaws.com

# Windows (PowerShell)
(Invoke-WebRequest -Uri "https://checkip.amazonaws.com").Content.Trim()
```

Note the output — you will use it as `YOUR_IP/32` (e.g. `203.0.113.42/32`).

---

## Steps

### 1 — See the policy block a violation

Initialise and run the wrapper script. The default SSH source is `0.0.0.0/0`,
which triggers two policy failures.

```bash
cd 03-policy-as-code

terraform init
bash policy-apply.sh
```

Expected output:

```
FAIL - plan.json - [SG-001] Security group 'aws_security_group.ec2' allows
public ingress (0.0.0.0/0) on sensitive port 22. Restrict to a private CIDR.

FAIL - plan.json - [SG-003] Security group 'aws_security_group.ec2' allows SSH
from '0.0.0.0/0'. SSH source must be a single host (/32).

================================================================
  POLICY VIOLATION — deployment blocked
  Fix the violations above before applying.
================================================================
```

No resource was created. `terraform apply` never ran.

---

### 2 — Fix the violation

Create a `terraform.tfvars` file with your public IP:

```bash
# macOS / Linux
echo "allowed_ssh_cidr = \"$(curl -s https://checkip.amazonaws.com)/32\"" > terraform.tfvars

# Windows (PowerShell)
$ip = (Invoke-WebRequest -Uri "https://checkip.amazonaws.com").Content.Trim()
"allowed_ssh_cidr = `"$ip/32`"" | Out-File -Encoding utf8 terraform.tfvars
```

The file should contain:

```hcl
allowed_ssh_cidr = "YOUR_IP/32"
```

---

### 3 — Re-run and confirm the policy passes

```bash
bash policy-apply.sh
```

Expected output:

```
================================================================
  All policies passed. Proceeding with apply...
================================================================
```

Conftest exits 0 — `terraform apply` runs and the infrastructure is deployed
with the correct, restricted SSH rule.

---

## How the enforcement works

`policy-apply.sh` is a drop-in replacement for `terraform apply`:

```
terraform plan -out plan.bin
terraform show -json plan.bin > plan.json
conftest test plan.json --policy policies/ --all-namespaces
  └─ exit 1 → print violation summary, exit — apply never runs
  └─ exit 0 → terraform apply plan.bin
```

Running `terraform apply` directly bypasses this check. The CI/CD pipeline
in Lab 4 is what enforces it automatically on every PR so no one can skip it.

---

## The Policy Files

| File | What it enforces |
|------|-----------------|
| [`policies/no-public-ingress.rego`](./policies/no-public-ingress.rego) | Blocks public SSH/RDP and enforces `/32` host restriction |
| [`policies/required-tags.rego`](./policies/required-tags.rego) | Requires `Environment` and `ManagedBy` on all resources |
| [`policies/iam-no-wildcards.rego`](./policies/iam-no-wildcards.rego) | Denies IAM wildcard actions, resources, or principals |
| [`policies/s3-encryption.rego`](./policies/s3-encryption.rego) | Mandates AES256 or KMS encryption on S3 buckets |

All policies are version-controlled. Changing a policy requires a code review,
the same as changing infrastructure. No one can quietly whitelist a rule.

---

**The Lab 1 EC2 is still running. Move to Lab 4.**
