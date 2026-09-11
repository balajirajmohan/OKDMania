variable "aws_region" {
  type        = string
  description = "Same account as OKD. Prefer ap-south-1 if the team is IST (D013)."
  default     = "ap-south-1"
}

variable "github_repo" {
  type        = string
  description = "owner/name that this runner will serve."
  default     = "balajirajmohan/OKDMania"
}

variable "github_runner_token" {
  type        = string
  sensitive   = true
  description = "Registration token from GitHub Settings → Actions → Runners. Expires in 1 hour. Do not commit."

  validation {
    condition     = length(var.github_runner_token) > 12
    error_message = "Paste a fresh registration token (GitHub UI or `gh api`). It expires in one hour."
  }
}

variable "instance_type" {
  type        = string
  description = "Persistent runner. t3.large fits Terraform + Docker + the actions-runner process."
  default     = "t3.large"
}

variable "root_volume_gb" {
  type    = number
  default = 40
}

variable "name_prefix" {
  type    = string
  default = "okdmania-gha"
}

variable "vpc_cidr" {
  type        = string
  description = "Dedicated runner VPC. Leave 10.0.0.0/16 free for the OKD UPI cluster."
  default     = "10.10.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.10.1.0/24"
}

variable "runner_labels" {
  type        = string
  description = "Extra labels (self-hosted, linux, x64 are added by the runner app)."
  default     = "aws,okdmania"
}

variable "attach_administrator_access" {
  type        = bool
  description = "Set true when this runner will apply OKD UPI Terraform. Leave false for the first smoke test."
  default     = false
}

variable "additional_tags" {
  type        = map(string)
  description = "Merged into provider default_tags. Purpose=okdmania is always applied last and cannot be overridden here."
  default     = {}
}
