package terraform.compliance.security_groups

import rego.v1

# No security group may allow ingress from 0.0.0.0/0 or ::/0
# on sensitive ports (22, 3389, 1433, 3306, 5432, 6379, 27017).

sensitive_ports := {22, 3389, 1433, 3306, 5432, 6379, 27017}

public_cidrs := {"0.0.0.0/0", "::/0"}

deny contains msg if {
	sg := planned_security_groups[_]
	rule := sg.change.after.ingress[_]
	port := numbers.range(rule.from_port, rule.to_port)[_]
	sensitive_ports[port]
	cidr := rule.cidr_blocks[_]
	public_cidrs[cidr]
	msg := sprintf(
		"[SG-001] Security group '%s' allows public ingress (%s) on sensitive port %d. Restrict to a private CIDR.",
		[sg.address, cidr, port],
	)
}

deny contains msg if {
	sg := planned_security_groups[_]
	rule := sg.change.after.ingress[_]
	port := numbers.range(rule.from_port, rule.to_port)[_]
	sensitive_ports[port]
	cidr := rule.ipv6_cidr_blocks[_]
	public_cidrs[cidr]
	msg := sprintf(
		"[SG-001] Security group '%s' allows public IPv6 ingress (%s) on sensitive port %d.",
		[sg.address, cidr, port],
	)
}

# Warn (not deny) on wide-open egress — useful for awareness
warn contains msg if {
	sg := planned_security_groups[_]
	rule := sg.change.after.egress[_]
	rule.from_port == 0
	rule.to_port == 0
	rule.protocol == "-1"
	cidr := rule.cidr_blocks[_]
	public_cidrs[cidr]
	msg := sprintf(
		"[SG-002] Security group '%s' has unrestricted egress to %s. Consider limiting outbound traffic.",
		[sg.address, cidr],
	)
}

# SSH must be locked to a single host — /32 for IPv4, /128 for IPv6
deny contains msg if {
	sg := planned_security_groups[_]
	rule := sg.change.after.ingress[_]
	port := numbers.range(rule.from_port, rule.to_port)[_]
	port == 22
	cidr := rule.cidr_blocks[_]
	not endswith(cidr, "/32")
	msg := sprintf(
		"[SG-003] Security group '%s' allows SSH from '%s'. SSH source must be a single host (/32).",
		[sg.address, cidr],
	)
}

deny contains msg if {
	sg := planned_security_groups[_]
	rule := sg.change.after.ingress[_]
	port := numbers.range(rule.from_port, rule.to_port)[_]
	port == 22
	cidr := rule.ipv6_cidr_blocks[_]
	not endswith(cidr, "/128")
	msg := sprintf(
		"[SG-003] Security group '%s' allows SSH from '%s'. SSH source must be a single host (/128).",
		[sg.address, cidr],
	)
}

# ── helpers ──────────────────────────────────────────────────────────────────

planned_security_groups contains resource if {
	resource := input.resource_changes[_]
	resource.type == "aws_security_group"
	resource.change.actions[_] in ["create", "update"]
}
