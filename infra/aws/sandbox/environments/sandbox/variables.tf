# ===========================================================================
# Sandbox environment inputs
# ===========================================================================

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

# --- Networking ----------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR for OKD-VPC."
  type        = string
  default     = "10.50.0.0/16"
}

variable "azs" {
  description = "AZs for the subnets. Must exist in var.aws_region."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDRs (index-aligned with var.azs)."
  type        = list(string)
  default     = ["10.50.0.0/24", "10.50.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDRs. Empty for the initial public-only sandbox."
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway for private subnets (costs money - keep false)."
  type        = bool
  default     = false
}

# --- Access control ----------------------------------------------------
variable "admin_cidrs" {
  description = <<-EOT
    REQUIRED. Trusted CIDRs allowed to SSH to every instance. No default, and
    0.0.0.0/0 is rejected. Find yours: `curl -s https://checkip.amazonaws.com`
    then append /32.
  EOT
  type        = list(string)
}

variable "cluster_api_cidrs" {
  description = "CIDRs allowed to reach the OKD API (6443) on the master. Defaults to admin_cidrs."
  type        = list(string)
  default     = []
}

variable "apps_ingress_cidrs" {
  description = "CIDRs allowed to reach app HTTP/HTTPS (80/443). Default: internet (learning apps)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# --- AMIs  (spec sections 5 & 6) --------------------------------------
variable "fedora_ami_id" {
  description = <<-EOT
    REQUIRED. AMI ID for the Fedora Cloud Base image in var.aws_region, used by
    BOTH master and worker so their Fedora versions match.

    Why a variable and not an aws_ami data source?
      This AWS account has an SCP that explicitly denies ec2:DescribeImages, so
      data "aws_ami" fails at plan time. See docs/sandbox-findings.md.

    How to find the current ID (any one of):
      * https://fedoraproject.org/cloud/download  -> pick region -> the
        "Launch" link's ImageId, or the AMI table
      * (if the SCP is lifted) aws ec2 describe-images --owners 125523088429 \
          --filters 'Name=name,Values=Fedora-Cloud-Base-*' \
          'Name=architecture,Values=x86_64' \
          --query 'reverse(sort_by(Images,&CreationDate))[0].ImageId'
      * AWS Console -> EC2 -> AMIs -> Public images -> owner 125523088429
  EOT
  type        = string

  validation {
    condition     = can(regex("^ami-[0-9a-f]{8,}$", var.fedora_ami_id))
    error_message = "fedora_ami_id must look like ami-xxxxxxxxxxxxxxxxx."
  }
}

variable "ubuntu_ami_id" {
  description = <<-EOT
    AMI ID for Ubuntu 24.04 LTS (server, amd64), used by okd-ansible and
    okd-runner. Leave "" to resolve the current one from the Canonical SSM
    public parameter (this works even with the DescribeImages SCP).
  EOT
  type        = string
  default     = ""
}

variable "ubuntu_ssm_parameter" {
  description = "SSM public parameter path for the Ubuntu AMI when ubuntu_ami_id is empty."
  type        = string
  default     = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

# --- Instances  (spec section 4) ------------------------------------
variable "master_instance_type" {
  description = "OKD master instance type. m5.xlarge = 4 vCPU / 16 GiB (OKD control-plane minimum)."
  type        = string
  default     = "m5.xlarge"
}

variable "worker_instance_type" {
  description = "OKD worker instance type."
  type        = string
  default     = "t3.xlarge"
}

variable "ansible_instance_type" {
  description = "Ansible control node instance type."
  type        = string
  default     = "t3.xlarge"
}

variable "runner_instance_type" {
  description = "CI/CD runner instance type."
  type        = string
  default     = "t3.xlarge"
}

variable "master_root_volume_size" {
  description = "Root volume GiB for the master."
  type        = number
  default     = 60
}

variable "node_root_volume_size" {
  description = "Root volume GiB for worker / ansible / runner."
  type        = number
  default     = 40
}

# --- Key pair  (spec section 7) ------------------------------------
variable "key_name" {
  description = "EC2 key pair name to create."
  type        = string
  default     = "okd-project"
}

variable "public_key_path" {
  description = "Path to the public key file (run scripts/generate-key.sh first)."
  type        = string
  default     = "../../scripts/okd-project.pem.pub"
}

variable "ssh_private_key_file" {
  description = "Where the private key lives on the machine that will run Ansible (written into the generated inventory)."
  type        = string
  default     = "~/.ssh/okd-project.pem"
}

# --- Optional IAM ------------------------------------------------------
variable "create_instance_profile" {
  description = "Attach an SSM-only IAM instance profile to the nodes (Session Manager access)."
  type        = bool
  default     = false
}

# --- Ansible inventory generation -----------------------------------
variable "generate_ansible_inventory" {
  description = "Write ansible/inventory/hosts.ini from the instance IPs on apply."
  type        = bool
  default     = true
}

variable "ansible_inventory_path" {
  description = "Path (relative to this stack dir) for the generated inventory file. Default points at repo-root ansible/inventory/hosts.ini (5 levels up)."
  type        = string
  default     = "../../../../../ansible/inventory/hosts.ini"
}
