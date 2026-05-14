# Lab 4 — CI/CD with GitHub Actions

## Goal

Automate everything from Labs 1–3 so no security check relies on a human
remembering to run it.

## What the Pipeline Does

```
Pull Request opened
  └─ Plan the infra
  └─ Run OPA policy check  ← if this fails, PR is blocked

Merged to main
  └─ terraform apply        ← infrastructure is deployed

Every 6 hours (scheduled)
  └─ terraform plan -detailed-exitcode
      ├─ exit 0 → no drift, nothing to do
      └─ exit 2 → drift found → open a GitHub Issue automatically
```

## Pipeline File

[.github/workflows/terraform-compliance.yml](../.github/workflows/terraform-compliance.yml)

> This file lives at the **repo root**, not inside this folder.
> GitHub Actions only picks up workflows from `<repo-root>/.github/workflows/`.

## Setup

### 1 — Create an IAM role with OIDC trust for GitHub Actions

GitHub Actions uses a short-lived OIDC token instead of long-lived AWS keys.
No `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` stored anywhere.

```bash
# Trust policy for the IAM role:
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
      "token.actions.githubusercontent.com:sub": "repo:<YOUR_ORG>/<YOUR_REPO>:ref:refs/heads/main"
    }
  }
}
```

### 2 — Add GitHub Secrets

| Secret | Value |
|--------|-------|
| `AWS_CI_ROLE_ARN` | ARN of the IAM role above |
| `ALLOWED_SSH_CIDR` | Your IP in CIDR notation e.g. `203.0.113.42/32` |

### 3 — Create a `production` GitHub Environment

Settings → Environments → New environment → `production`

Add a required reviewer. This means `terraform apply` on main requires a human
to approve before it runs.

## Demo Talking Points

- **PR flow**: open a PR with `0.0.0.0/0` in the SSH rule → the policy check job
  fails → the PR shows a red check → the violation is described in a PR comment.

- **Main flow**: fix the rule → PR merges → apply runs automatically → infra is
  deployed with the correct config.

- **Drift flow**: make a manual change in the console → wait for the 6-hour
  schedule (or trigger the workflow manually) → a GitHub Issue appears with the
  exact diff.

The pipeline replaces three manual steps — `conftest`, `terraform apply`, and
`terraform plan` on a schedule — with one automated workflow that runs on every
relevant event.
