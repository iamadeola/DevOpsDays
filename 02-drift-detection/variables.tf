variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "prefix" {
  type    = string
  default = "devopsday"
}

variable "environment" {
  type    = string
  default = "demo"
}

variable "allowed_ssh_cidr" {
  description = "Your IP address in CIDR notation (e.g. 203.0.113.42/32). Only this IP may SSH to the instance."
  type        = string
  # No default — must be set explicitly so you don't accidentally open to the world.
  # Find your IP: curl -s https://checkip.amazonaws.com
}

variable "key_pair_name" {
  description = "Name of an existing EC2 Key Pair to attach to the instance for SSH access"
  type        = string
  default     = ""
}
