variable "create" {
  description = "Whether to create the role + instance profile at all."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name for the IAM role and instance profile."
  type        = string
  default     = "OKD-Node"
}

variable "enable_ssm" {
  description = "Attach AmazonSSMManagedInstanceCore (Session Manager shell without opening SSH)."
  type        = bool
  default     = true
}

variable "extra_policy_arns" {
  description = "Additional managed policy ARNs to attach. Keep least-privilege."
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional inline IAM policy JSON to attach (e.g. for permissions no managed policy covers). Null to skip."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
