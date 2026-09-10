variable "name" {
  description = "Name tag for the VPC and prefix for subnet/route-table names."
  type        = string
  default     = "OKD-VPC"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.50.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR."
  }
}

variable "azs" {
  description = "Availability zones to spread subnets across (e.g. [\"us-east-1a\",\"us-east-1b\"])."
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets. One per AZ (index-aligned with var.azs)."
  type        = list(string)
  default     = ["10.50.0.0/24", "10.50.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = <<-EOT
    CIDR blocks for private subnets. Leave [] for the initial public-only
    sandbox. When set, the module creates private subnets + a private route
    table. This is the "make private subnets easy to add later" hook.
  EOT
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = <<-EOT
    Create a NAT gateway (+ EIP) so private subnets reach the internet.
    Costs ~$32/month + data. Keep false for the sandbox (spec section 21).
    Only meaningful when private_subnet_cidrs is non-empty.
  EOT
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "If NAT is enabled, use one shared NAT gateway instead of one per AZ."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to every resource in this module."
  type        = map(string)
  default     = {}
}
