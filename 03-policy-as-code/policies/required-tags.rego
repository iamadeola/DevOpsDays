package terraform.compliance.tagging

import rego.v1

# All resources must have Environment and ManagedBy tags.
# Untagged resources are untracked resources — a cost and security risk.

required_tags := {"Environment", "ManagedBy"}

taggable_types := {
	"aws_s3_bucket",
	"aws_security_group",
	"aws_iam_role",
	"aws_iam_policy",
	"aws_instance",
	"aws_db_instance",
	"aws_kms_key",
}

deny contains msg if {
	resource := planned_taggable_resources[_]
	tag := required_tags[_]
	not resource.change.after.tags[tag]
	msg := sprintf(
		"[TAG-001] Resource '%s' is missing required tag '%s'.",
		[resource.address, tag],
	)
}

# ── helpers ──────────────────────────────────────────────────────────────────

planned_taggable_resources contains resource if {
	resource := input.resource_changes[_]
	taggable_types[resource.type]
	resource.change.actions[_] in ["create", "update"]
}
