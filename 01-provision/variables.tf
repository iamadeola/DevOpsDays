variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "allowed_ssh_cidr" {
  description = "Your public IP in CIDR notation. Run: curl -s https://checkip.amazonaws.com"
  type        = string
}

variable "key_pair_name" {
  description = "Existing EC2 Key Pair name for SSH access. Leave empty if not needed."
  type        = string
  default     = ""
}
