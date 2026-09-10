variable "create" {
  description = "Whether to create the role + instance profile at all."
  type        = bool
  default     = false
}

variable "name" {
  description = "Name for the IAM role and instance profile."
  type        = string
  default     = "okd-sandbox-node"
}

variable "enable_ssm" {
  description = "Attach AmazonSSMManagedInstanceCore (Session Manager shell without opening SSH)."
  type        = bool
  default     = true
}

variable "extra_policy_arns" {
  description = "Additional managed policy ARNs to attach. Keep least-privilege (spec section 13)."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
