variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "allowed_ssh_cidr" {
  description = "Your IP in CIDR notation (e.g. 203.0.113.42/32)"
  type        = string
}
