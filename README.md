# The DevSecOps Angle: State Management and Compliance with Terraform

**DevOpsDays Sibiu — Workshop**

---

## The Story

One EC2 instance. One security group. Four labs — each one building on the last.

We start by provisioning correctly. We break it, detect it, fix it, block it,
and finally automate all of it inside a CI/CD pipeline.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Terraform | >= 1.6 | https://developer.hashicorp.com/terraform/install |
| AWS CLI | >= 2.x | https://aws.amazon.com/cli/ |
| Conftest | >= 0.46 | https://www.conftest.dev (needed from Lab 3) |
| jq | any | https://jqlang.github.io/jq/ |

```bash
aws configure   # or export AWS_PROFILE=your-profile
```

---

## Lab Flow

```
Lab 1                   Lab 2                   Lab 3                   Lab 4
─────────────────────   ─────────────────────   ─────────────────────   ─────────────────────
Provision EC2           Drift Detection         Policy as Code          CI/CD Pipeline
                                                                        (GitHub Actions)
terraform apply         Rogue user opens        terraform destroy
                        SSH → 0.0.0.0/0                                 Policy check on PR
EC2 running,            in the console          Try to redeploy
SSH from your                                   with 0.0.0.0/0          Drift check on
IP only                 terraform plan                                  a schedule
                        detects it              conftest BLOCKS it
                                                                        terraform apply
                        terraform apply         Fix the rule            on merge
                        reverts it
                                                terraform apply
                                                succeeds
```

| # | Directory | Lab | Time |
|---|-----------|-----|------|
| 1 | [01-provision/](./01-provision/) | Provision EC2 with SSH from your IP | 15 min |
| 2 | [02-drift-detection/](./02-drift-detection/) | Introduce drift, detect it, revert it | 20 min |
| 3 | [03-policy-as-code/](./03-policy-as-code/) | Block a bad deploy before it happens | 20 min |
| 4 | [04-ci-pipeline/](./04-ci-pipeline/) | Automate everything in GitHub Actions | 15 min |

---

## Cleanup

```bash
# Run from whichever lab directory was last used:
terraform destroy -auto-approve
```
