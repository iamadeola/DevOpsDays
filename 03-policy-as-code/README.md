# Lab 3 — Policy as Code

> **The EC2 from Lab 1 keeps running throughout this lab.**
> Lab 3 is a standalone plan-only exercise — no resources are destroyed
> or created. We generate a plan and test it against a policy.

## The Scenario

After the Lab 2 incident, a developer decides to make the `0.0.0.0/0` SSH
rule permanent in code so they can always connect from anywhere. They update
`main.tf` and open a PR.

`terraform validate` passes. `terraform plan` succeeds.

But the OPA policy check **blocks the PR before anything reaches production**.

## What is Policy as Code?

```
PR opened
  └─ terraform plan → plan.json → conftest → FAIL  ← blocked here
                                           → PASS  ← deploy proceeds
```

Instead of relying on a human reviewer to catch the bad SSH rule, a
machine-readable policy runs automatically on every PR. It lives in version
control. It can't be skipped.

---

## Steps

### 1 — Install Conftest (if not already installed)

```bash
# macOS
brew install conftest

# Windows
choco install conftest

# Linux
curl -Lo conftest.tar.gz \
  https://github.com/open-policy-agent/conftest/releases/download/v0.46.0/conftest_0.46.0_Linux_x86_64.tar.gz
tar xzf conftest.tar.gz && sudo mv conftest /usr/local/bin/
```

---

### 2 — Generate the plan

```bash
cd ../03-policy-as-code

terraform init
terraform plan -out plan.bin
terraform show -json plan.bin > plan.json
```

---

### 3 — Run the policy check

```bash
conftest test plan.json --policy policies/ --all-namespaces
```

Expected output:

```
FAIL - plan.json - terraform.compliance.security_groups - [SG-001] Security group
'aws_security_group.ec2' allows public SSH ingress from 0.0.0.0/0.
Restrict to a specific CIDR.

1 test, 0 passed, 0 warnings, 1 failure
```

The policy failed. No resource has been created. The PR would be blocked here.

---

### 4 — Fix the violation

Open `main.tf` and change the SSH source to your IP:

```hcl
# Before (violation):
cidr_blocks = ["0.0.0.0/0"]

# After (compliant):
cidr_blocks = ["203.0.113.42/32"]   # your IP
```

Re-generate the plan and re-run the policy check:

```bash
terraform plan -out plan.bin
terraform show -json plan.bin > plan.json
conftest test plan.json --policy policies/ --all-namespaces
```

```
1 test, 1 passed, 0 warnings, 0 failures
```

Policy passes. The PR would now be unblocked.

---

## The Policy File

[policies/no-public-ingress.rego](./policies/no-public-ingress.rego)

Written in Rego (OPA's policy language). It reads the Terraform plan JSON
and denies any security group that allows SSH from `0.0.0.0/0` or `::/0`.

The policy is version-controlled — changing it requires a code review,
the same as changing infrastructure. No one can quietly whitelist a rule.

---

**The Lab 1 EC2 is still running. Move to Lab 4.**
