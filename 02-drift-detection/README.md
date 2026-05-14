# Lab 2 — Drift Detection

> **Important:** All commands in this lab run from the `01-provision/` directory.
> That is where the Terraform state lives. Do not run `terraform` commands
> from inside `02-drift-detection/`.

## Prerequisite

Lab 1 is complete and the EC2 is running.

## The Scenario

A developer cannot SSH into the instance from home. Instead of going through
the proper channel, they log into the AWS Console and add an SSH rule open to
`0.0.0.0/0` — bypassing Terraform entirely.

The instance is now exposed to the internet. Nobody knows.

---

## Steps

### 1 — Confirm the clean baseline

```bash
cd ../01-provision

aws ec2 describe-security-groups \
  --group-ids $(terraform output -raw security_group_id) \
  --query 'SecurityGroups[0].IpPermissions'
```

Only your IP is in the rule. No `0.0.0.0/0`.

---

### 2 — Introduce the drift

**Option A — live in the AWS Console (most visual for the audience):**
1. Open AWS Console → EC2 → Security Groups
2. Find `devopsday-ec2-sg`
3. Edit inbound rules → Add rule → Type: SSH, Source: Anywhere IPv4 (`0.0.0.0/0`)
4. Save rules

**Option B — via script (fastest for demo):**
```bash
# still from 01-provision/
bash ../02-drift-detection/simulate-drift.sh
```

Show the audience the security group in the console now has two SSH rules.

---

### 3 — Detect the drift

```bash
# still from 01-provision/
terraform plan
```

Terraform compares state against reality and reports exactly what changed:

```diff
  ~ resource "aws_security_group" "ec2" {
      ~ ingress = [
          + {
              + cidr_blocks = ["0.0.0.0/0"]
              + from_port   = 22
              + protocol    = "tcp"
              + to_port     = 22
            },
        ]
    }

Plan: 0 to add, 1 to change, 0 to destroy.
```

`terraform plan` **is** the drift detector. No extra tool needed.

---

### 4 — Revert the drift

```bash
terraform apply
```

Terraform removes the rogue `0.0.0.0/0` rule and restores the declared state.

**Verify in the console** — the `0.0.0.0/0` rule is gone.

---

### 5 — Automated drift check

```bash
bash ../02-drift-detection/drift-check.sh
```

This is what the CI/CD pipeline (Lab 4) runs on a schedule every 6 hours.
If it exits with code `2`, the pipeline opens a GitHub Issue automatically.

---

## Key Point

The rogue change was **temporary**. The next `terraform apply` erased it.
Compliance isn't a one-time audit — it's a continuous loop enforced by the pipeline.

---

**The EC2 stays running. Move directly to Lab 3.**
