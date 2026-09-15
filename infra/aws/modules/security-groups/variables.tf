variable "name_prefix" {
  description = "Prefix for security group names, e.g. \"OKD\"."
  type        = string
  default     = "OKD"
}

variable "vpc_id" {
  description = "VPC the security groups belong to."
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR - used for intra-VPC rules like DNS and ICMP."
  type        = string
}

variable "admin_cidrs" {
  description = <<-EOT
    Trusted CIDRs allowed to SSH (port 22) to every instance. REQUIRED - there
    is no default and 0.0.0.0/0 is never used for SSH (spec section 8).
    Example: ["203.0.113.10/32"] for your office / VPN egress IP.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.admin_cidrs) > 0
    error_message = "Provide at least one admin CIDR."
  }
}

variable "cluster_api_cidrs" {
  description = <<-EOT
    CIDRs allowed to reach the Kubernetes/OKD API on the master (port 6443).
    Defaults to admin_cidrs. Widen only if you need `oc` access from elsewhere;
    document why in the README (spec section 8).
  EOT
  type        = list(string)
  default     = []
}

variable "apps_ingress_cidrs" {
  description = <<-EOT
    CIDRs allowed to reach application HTTP/HTTPS (ports 80/443) on the nodes -
    i.e. the OpenShift router / your deployed apps. Defaults to the internet
    because a learning cluster's demo apps are meant to be reachable; tighten
    for anything sensitive (spec section 8 asks you to document this).
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
