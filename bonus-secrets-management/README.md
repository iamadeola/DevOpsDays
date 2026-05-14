# Lab 4 — Secrets Management

## The Story

Same EC2 instance. A developer adds an app secret directly into `user_data`
so the instance picks it up on boot. It works — but the secret is now sitting
in `terraform.tfstate` in plain text, readable by anyone with state access.

## Prove it with the bad pattern

```bash
cd bad/
terraform apply -var='app_secret=SuperSecret123!'

# Extract user_data from state and decode it:
cat terraform.tfstate \
  | jq -r '.resources[] | select(.type=="aws_instance") | .instances[].attributes.user_data' \
  | base64 -d
```

Output:
```bash
#!/bin/bash
export APP_SECRET=SuperSecret123!
echo "APP_SECRET=SuperSecret123!" >> /etc/environment
```

The secret is right there. `sensitive = true` on the variable hid it from
the terminal — it did nothing to protect the state file.

## The fix

```
bad/  → secret passed as variable → stored in state (plaintext)
good/ → secret stored in SSM Parameter Store → state contains only the ARN
        EC2 fetches the real value at boot via AWS CLI (never touches Terraform)
```

```bash
cd good/

# Terraform creates the SSM parameter slot (with a placeholder value)
terraform apply -var='allowed_ssh_cidr=YOUR_IP/32'

# You (or CI) set the real value — outside Terraform
aws ssm put-parameter \
  --name "/devopsday/demo/app-secret" \
  --value "SuperSecret123!" \
  --type SecureString \
  --overwrite

# Now check state — only the ARN is there, never the value
cat terraform.tfstate \
  | jq '.resources[] | select(.type=="aws_ssm_parameter") | .instances[].attributes | {name, arn}'
```

## The Rule

Terraform manages **where** secrets live and **who** can access them.
It never carries the secret value itself.

| | `bad/` | `good/` |
|--|--------|---------|
| Secret in state? | Yes — plaintext | No — ARN only |
| Rotation | Manual redeploy | `aws ssm put-parameter --overwrite` |
| Audit trail | None | CloudTrail logs every `GetParameter` call |
| Who can read it | Anyone with state access | IAM-controlled, logged |
