variable "name" {
  description = "Name tag / hostname for the instance (e.g. OKD-master)."
  type        = string
}

variable "role" {
  description = "Role tag: master | worker | ansible | runner."
  type        = string
}

variable "os" {
  description = "OS tag: Fedora | Ubuntu."
  type        = string
}

variable "ami_id" {
  description = "AMI ID to launch."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "subnet_id" {
  description = "Subnet to launch into."
  type        = string
}

variable "vpc_security_group_ids" {
  description = "Security group IDs to attach."
  type        = list(string)
}

variable "key_name" {
  description = "EC2 key pair name."
  type        = string
}

variable "user_data" {
  description = "Rendered cloud-init user data."
  type        = string
  default     = null
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 40
}

variable "root_volume_type" {
  description = "Root EBS volume type."
  type        = string
  default     = "gp3"
}

variable "associate_public_ip" {
  description = "Assign a public IP (false for private-subnet instances like the worker)."
  type        = bool
  default     = true
}

variable "iam_instance_profile" {
  description = "Optional IAM instance profile name (e.g. for SSM Session Manager)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags merged under the per-instance Name/Role/OS tags."
  type        = map(string)
  default     = {}
}
