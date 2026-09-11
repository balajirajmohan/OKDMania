variable "aws_region" {
  type        = string
  description = "Must be the region of Vignesh's OKD-VPC (us-east-1 on origin/infra)."
  default     = "us-east-1"
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

variable "vpc_id" {
  type        = string
  description = "Existing VPC. Leave empty to look up by vpc_name tag (OKD-VPC)."
  default     = ""
}

variable "vpc_name" {
  type        = string
  description = "Name tag of Vignesh's VPC when vpc_id is empty."
  default     = "OKD-VPC"
}

variable "subnet_id" {
  type        = string
  description = "Public subnet in that VPC. Leave empty to pick the first subnet tagged Tier=public."
  default     = ""
}

variable "ubuntu_ssm_parameter" {
  type        = string
  description = "Canonical Ubuntu AMI SSM parameter (avoids ec2:DescribeImages SCP)."
  default     = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
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
