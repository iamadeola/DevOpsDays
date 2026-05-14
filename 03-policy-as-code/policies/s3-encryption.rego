package terraform.compliance.s3

import rego.v1

# Every S3 bucket must have server-side encryption configured.

deny contains msg if {
	bucket := planned_s3_buckets[_]
	not has_encryption(bucket.address)
	msg := sprintf(
		"[S3-001] S3 bucket '%s' has no server-side encryption. Add aws_s3_bucket_server_side_encryption_configuration.",
		[bucket.address],
	)
}

deny contains msg if {
	enc := planned_encryptions[_]
	algo := enc.values.rule[_].apply_server_side_encryption_by_default[_].sse_algorithm
	not valid_algorithm(algo)
	msg := sprintf(
		"[S3-002] S3 encryption on '%s' uses weak algorithm '%s'. Use AES256 or aws:kms.",
		[enc.values.bucket, algo],
	)
}

# ── helpers ──────────────────────────────────────────────────────────────────

planned_s3_buckets contains resource if {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket"
	resource.change.actions[_] in ["create", "update"]
}

planned_encryptions contains resource if {
	resource := input.resource_changes[_]
	resource.type == "aws_s3_bucket_server_side_encryption_configuration"
	resource.change.actions[_] in ["create", "update"]
}

has_encryption(bucket_address) if {
	enc := planned_encryptions[_]
	# enc resource's `bucket` attribute references the bucket address (module path stripped)
	endswith(bucket_address, split(enc.values.bucket, ".")[count(split(enc.values.bucket, ".")) - 1])
}

# Also accept when the bucket's own `server_side_encryption_configuration` block is set inline
has_encryption(bucket_address) if {
	resource := input.resource_changes[_]
	resource.address == bucket_address
	resource.change.after.server_side_encryption_configuration != null
	count(resource.change.after.server_side_encryption_configuration) > 0
}

valid_algorithm(algo) if algo == "AES256"
valid_algorithm(algo) if algo == "aws:kms"
