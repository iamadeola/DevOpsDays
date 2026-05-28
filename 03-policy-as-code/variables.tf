variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "key_pair_name" {
  type    = string
  default = ""
}

variable "allowed_ssh_cidr" {
  description = "SSH source CIDR. Defaults to 0.0.0.0/0 to demonstrate the policy violation. Override in terraform.tfvars to fix."
  type        = string
  default     = "0.0.0.0/0"
}
