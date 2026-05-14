package terraform.compliance.iam

import rego.v1

# IAM policies must not use wildcard actions (*) or wildcard resources (*).
# Wildcard actions with Allow grant unrestricted access — classic privilege escalation path.

deny contains msg if {
	policy_resource := planned_iam_policies[_]
	doc := json.unmarshal(policy_resource.change.after.policy)
	statement := doc.Statement[_]
	statement.Effect == "Allow"
	is_wildcard_action(statement.Action)
	msg := sprintf(
		"[IAM-001] IAM policy '%s' contains a wildcard Action ('*') in an Allow statement. Use least-privilege actions.",
		[policy_resource.address],
	)
}

deny contains msg if {
	policy_resource := planned_iam_policies[_]
	doc := json.unmarshal(policy_resource.change.after.policy)
	statement := doc.Statement[_]
	statement.Effect == "Allow"
	not is_wildcard_action(statement.Action) # only warn on resource wildcard when action is specific
	is_wildcard_resource(statement.Resource)
	msg := sprintf(
		"[IAM-002] IAM policy '%s' uses wildcard Resource ('*'). Scope resources to specific ARNs.",
		[policy_resource.address],
	)
}

deny contains msg if {
	role := planned_iam_roles[_]
	doc := json.unmarshal(role.change.after.assume_role_policy)
	statement := doc.Statement[_]
	statement.Effect == "Allow"
	principal_is_wildcard(statement.Principal)
	msg := sprintf(
		"[IAM-003] IAM role '%s' has a wildcard Principal in its trust policy. Anyone can assume this role.",
		[role.address],
	)
}

# ── helpers ──────────────────────────────────────────────────────────────────

is_wildcard_action(action) if action == "*"
is_wildcard_action(actions) if {
	is_array(actions)
	actions[_] == "*"
}

is_wildcard_resource(resource) if resource == "*"
is_wildcard_resource(resources) if {
	is_array(resources)
	resources[_] == "*"
}

principal_is_wildcard(principal) if principal == "*"
principal_is_wildcard(principal) if principal.AWS == "*"

planned_iam_policies contains resource if {
	resource := input.resource_changes[_]
	resource.type == "aws_iam_policy"
	resource.change.actions[_] in ["create", "update"]
}

planned_iam_roles contains resource if {
	resource := input.resource_changes[_]
	resource.type == "aws_iam_role"
	resource.change.actions[_] in ["create", "update"]
}
