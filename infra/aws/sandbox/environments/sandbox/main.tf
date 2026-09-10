# ===========================================================================
# OKD sandbox environment - wires the modules together
# ===========================================================================
#   vpc              -> OKD-VPC, IGW, public subnets, public route table
#   security-groups  -> master / worker / ansible / runner SGs
#   key-pair         -> imports okd-project public key
#   iam-instance-profile (optional) -> SSM Session Manager
#   ec2 x4           -> OKD-master, OKD-worker, okd-ansible, okd-runner
#
# The two Fedora nodes are a learning/tooling surface, NOT an OKD 4.x cluster.
# See docs/sandbox-findings.md.
# ===========================================================================

# --- Ubuntu AMI: variable override, else Canonical SSM public parameter ---
data "aws_ssm_parameter" "ubuntu" {
  count = var.ubuntu_ami_id == "" ? 1 : 0
  name  = var.ubuntu_ssm_parameter
}

locals {
  # insecure_value: non-sensitive attribute for String params (provider >=4.22).
  # try(): the data source has count=0 when ubuntu_ami_id is set.
  ubuntu_ami_id = coalesce(
    var.ubuntu_ami_id,
    try(data.aws_ssm_parameter.ubuntu[0].insecure_value, null),
  )
}

# --- Network -----------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  name                 = "OKD-VPC"
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  tags                 = local.common_tags
}

# --- Security groups -------------------------------------------------
module "security_groups" {
  source = "../../modules/security-groups"

  name_prefix        = "okd-sandbox"
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr_block
  admin_cidrs        = var.admin_cidrs
  cluster_api_cidrs  = var.cluster_api_cidrs
  apps_ingress_cidrs = var.apps_ingress_cidrs
  tags               = local.common_tags
}

# --- Key pair --------------------------------------------------------
module "key_pair" {
  source = "../../modules/key-pair"

  key_name = var.key_name
  # Resolve relative to this stack dir so it works regardless of CWD / -chdir.
  public_key_path = abspath("${path.module}/${var.public_key_path}")
  tags            = local.common_tags
}

# --- Optional IAM instance profile (SSM) ---------------------------
module "instance_profile" {
  source = "../../modules/iam-instance-profile"

  create = var.create_instance_profile
  name   = "okd-sandbox-node"
  tags   = local.common_tags
}

# --- EC2 instances -------------------------------------------------
module "okd_master" {
  source = "../../modules/ec2"

  name                   = "OKD-master"
  role                   = "master"
  os                     = "Fedora"
  ami_id                 = var.fedora_ami_id
  instance_type          = var.master_instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [module.security_groups.master_sg_id]
  key_name               = module.key_pair.key_name
  root_volume_size       = var.master_root_volume_size
  iam_instance_profile   = module.instance_profile.instance_profile_name
  tags                   = local.common_tags

  user_data = templatefile("${path.module}/../../templates/cloud-init-fedora.yaml.tftpl", {
    hostname        = "okd-master"
    role            = "master"
    internal_domain = local.internal_domain
  })
}

module "okd_worker" {
  source = "../../modules/ec2"

  name                   = "OKD-worker"
  role                   = "worker"
  os                     = "Fedora"
  ami_id                 = var.fedora_ami_id
  instance_type          = var.worker_instance_type
  subnet_id              = module.vpc.public_subnet_ids[length(module.vpc.public_subnet_ids) > 1 ? 1 : 0]
  vpc_security_group_ids = [module.security_groups.worker_sg_id]
  key_name               = module.key_pair.key_name
  root_volume_size       = var.node_root_volume_size
  iam_instance_profile   = module.instance_profile.instance_profile_name
  tags                   = local.common_tags

  user_data = templatefile("${path.module}/../../templates/cloud-init-fedora.yaml.tftpl", {
    hostname        = "okd-worker"
    role            = "worker"
    internal_domain = local.internal_domain
  })
}

module "okd_ansible" {
  source = "../../modules/ec2"

  name                   = "okd-ansible"
  role                   = "ansible"
  os                     = "Ubuntu"
  ami_id                 = local.ubuntu_ami_id
  instance_type          = var.ansible_instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [module.security_groups.ansible_sg_id]
  key_name               = module.key_pair.key_name
  root_volume_size       = var.node_root_volume_size
  iam_instance_profile   = module.instance_profile.instance_profile_name
  tags                   = local.common_tags

  user_data = templatefile("${path.module}/../../templates/cloud-init-ansible.yaml.tftpl", {
    hostname        = "okd-ansible"
    internal_domain = local.internal_domain
  })
}

module "okd_runner" {
  source = "../../modules/ec2"

  name                   = "okd-runner"
  role                   = "runner"
  os                     = "Ubuntu"
  ami_id                 = local.ubuntu_ami_id
  instance_type          = var.runner_instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [module.security_groups.runner_sg_id]
  key_name               = module.key_pair.key_name
  root_volume_size       = var.node_root_volume_size
  iam_instance_profile   = module.instance_profile.instance_profile_name
  tags                   = local.common_tags

  user_data = templatefile("${path.module}/../../templates/cloud-init-runner.yaml.tftpl", {
    hostname        = "okd-runner"
    internal_domain = local.internal_domain
  })
}
