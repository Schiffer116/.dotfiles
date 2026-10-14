variable "region" {
  description = "Parent region of the zone below."
  type        = string
  default     = "ap-southeast-1"
}

variable "zone" {
  description = "Hanoi Local Zone (needs a one-time opt-in). Fallback: \"ap-southeast-1a\" (Singapore)."
  type        = string
  default     = "ap-southeast-1-han-1a"
}

variable "instance_type" {
  description = "2 vCPU / 8 GiB. The Hanoi zone only offers C7i, M7i and R7i; r7i.large doubles the RAM."
  type        = string
  default     = "m7i.large"
}

variable "volume_size" {
  description = "Root gp3 volume in GiB: nix store, docker, worktrees, projects."
  type        = number
  default     = 50
}

variable "subnet_cidr" {
  description = "An unused block inside the default VPC, for the subnet in var.zone."
  type        = string
  default     = "172.31.128.0/24"
}

variable "bootstrap_ssh_cidr" {
  description = "\"<your public IP>/32\" for the first deploy only; set back to null once Tailscale works."
  type        = string
  default     = null

  validation {
    condition     = var.bootstrap_ssh_cidr == null || can(regex("^[0-9.]+/32$", var.bootstrap_ssh_cidr))
    error_message = "bootstrap_ssh_cidr must be a single IPv4 address as a /32."
  }
}

variable "bootstrap_public_key" {
  description = "SSH public key installed for root on first boot (EC2 key pair); null afterwards."
  type        = string
  default     = null
}
