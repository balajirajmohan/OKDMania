# ===========================================================================
# OKD AWS infrastructure - wires the modules together
# ===========================================================================
#   vpc              -> OKD-VPC, IGW, public + private subnets, NAT
#   security-groups  -> master / worker / ansible / runner SGs
#   key-pair         -> references the existing OKD-Project key pair
#   iam-instance-profile -> SSM Session Manager (on by default)
#   ec2 x4           -> OKD-Master, OKD-Worker, OKD-Ansible, OKD-Runner
#
# The Fedora nodes are a learning/tooling surface, not a full OKD 4.x
# cluster (OKD 4.x nodes run Fedora CoreOS + Ignition via openshift-install).
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
  source = "./modules/vpc"

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
  source = "./modules/security-groups"

  name_prefix        = "OKD"
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr_block
  admin_cidrs        = var.admin_cidrs
  cluster_api_cidrs  = var.cluster_api_cidrs
  apps_ingress_cidrs = var.apps_ingress_cidrs
  tags               = local.common_tags
}

# --- Key pair (references the existing OKD-Project key pair) --------
module "key_pair" {
  source = "./modules/key-pair"

  key_name = var.key_name
}

# --- IAM instance profile (SSM) --------------------------------------
module "instance_profile" {
  source = "./modules/iam-instance-profile"

  create = var.create_instance_profile
  name   = "OKD-Node"
  tags   = local.common_tags
}

# The Ansible box needs to be able to *initiate* SSM sessions and describe
# instances (for the dynamic inventory); AmazonSSMManagedInstanceCore alone
# only lets an instance *be* managed, not manage others. Scoped to
# Project = OKD-Project tagged instances rather than "*".
data "aws_iam_policy_document" "ansible_ssm" {
  statement {
    sid       = "StartSessionToOKDInstances"
    effect    = "Allow"
    actions   = ["ssm:StartSession"]
    resources = ["arn:aws:ec2:*:*:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "ssm:resourceTag/Project"
      values   = ["OKD-Project"]
    }
  }

  statement {
    sid       = "StartSessionDocument"
    effect    = "Allow"
    actions   = ["ssm:StartSession"]
    resources = ["arn:aws:ssm:*:*:document/SSM-SessionManagerRunShell"]
  }

  statement {
    sid       = "ManageOwnSessions"
    effect    = "Allow"
    actions   = ["ssm:TerminateSession", "ssm:ResumeSession"]
    resources = ["arn:aws:ssm:*:*:session/$${aws:username}"]
  }

  statement {
    sid       = "SSMDescribe"
    effect    = "Allow"
    actions   = ["ssm:DescribeSessions", "ssm:GetConnectionStatus", "ssm:DescribeInstanceInformation"]
    resources = ["*"]
  }

  statement {
    sid       = "DynamicInventory"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances", "ec2:DescribeTags", "ec2:DescribeInstanceStatus"]
    resources = ["*"]
  }
}

module "ansible_instance_profile" {
  source = "./modules/iam-instance-profile"

  create             = var.create_instance_profile
  name               = "OKD-Ansible-Node"
  inline_policy_json = data.aws_iam_policy_document.ansible_ssm.json
  tags               = local.common_tags
}

# --- EC2 instances -------------------------------------------------
module "okd_master" {
  source = "./modules/ec2"

  name                   = "OKD-Master"
  role                   = "Master"
  os                     = "Fedora"
  ami_id                 = var.fedora_ami_id
  instance_type          = var.master_instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [module.security_groups.master_sg_id]
  key_name               = module.key_pair.key_name
  root_volume_size       = var.master_root_volume_size
  iam_instance_profile   = module.instance_profile.instance_profile_name
  tags                   = local.common_tags

  user_data = templatefile("${path.module}/templates/cloud-init-fedora.yaml.tftpl", {
    hostname        = "okd-master"
    role            = "master"
    internal_domain = local.internal_domain
    aws_region      = var.aws_region
  })
}

# Worker sits in the private subnet - no public IP. NAT gives it outbound
# internet for package/image pulls; Ansible reaches it via SSM or, within the
# VPC, the ansible->worker security-group rule.
module "okd_worker" {
  source = "./modules/ec2"

  name                   = "OKD-Worker"
  role                   = "Worker"
  os                     = "Fedora"
  ami_id                 = var.fedora_ami_id
  instance_type          = var.worker_instance_type
  subnet_id              = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids = [module.security_groups.worker_sg_id]
  key_name               = module.key_pair.key_name
  associate_public_ip    = false
  root_volume_size       = var.node_root_volume_size
  iam_instance_profile   = module.instance_profile.instance_profile_name
  tags                   = local.common_tags

  user_data = templatefile("${path.module}/templates/cloud-init-fedora.yaml.tftpl", {
    hostname        = "okd-worker"
    role            = "worker"
    internal_domain = local.internal_domain
    aws_region      = var.aws_region
  })
}

module "okd_ansible" {
  source = "./modules/ec2"

  name                   = "OKD-Ansible"
  role                   = "Ansible"
  os                     = "Ubuntu"
  ami_id                 = local.ubuntu_ami_id
  instance_type          = var.ansible_instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [module.security_groups.ansible_sg_id]
  key_name               = module.key_pair.key_name
  root_volume_size       = var.node_root_volume_size
  iam_instance_profile   = module.ansible_instance_profile.instance_profile_name
  tags                   = local.common_tags

  user_data = templatefile("${path.module}/templates/cloud-init-ansible.yaml.tftpl", {
    hostname        = "okd-ansible"
    internal_domain = local.internal_domain
  })
}

module "okd_runner" {
  source = "./modules/ec2"

  name                   = "OKD-Runner"
  role                   = "Runner"
  os                     = "Ubuntu"
  ami_id                 = local.ubuntu_ami_id
  instance_type          = var.runner_instance_type
  subnet_id              = module.vpc.public_subnet_ids[0]
  vpc_security_group_ids = [module.security_groups.runner_sg_id]
  key_name               = module.key_pair.key_name
  root_volume_size       = var.node_root_volume_size
  iam_instance_profile   = module.instance_profile.instance_profile_name
  tags                   = local.common_tags

  user_data = templatefile("${path.module}/templates/cloud-init-runner.yaml.tftpl", {
    hostname        = "okd-runner"
    internal_domain = local.internal_domain
  })
}

# ===========================================================================
# Future masters and workers - disabled. Enable by uncommenting and adding
# a matching subnet index / cidr as needed. No restructuring required.
# ===========================================================================
#
# module "okd_master_02" {
#   source = "./modules/ec2"
#
#   name                   = "OKD-Master-02"
#   role                   = "Master"
#   os                     = "Fedora"
#   ami_id                 = var.fedora_ami_id
#   instance_type          = var.master_instance_type
#   subnet_id              = module.vpc.public_subnet_ids[1]
#   vpc_security_group_ids = [module.security_groups.master_sg_id]
#   key_name               = module.key_pair.key_name
#   root_volume_size       = var.master_root_volume_size
#   iam_instance_profile   = module.instance_profile.instance_profile_name
#   tags                   = local.common_tags
#
#   user_data = templatefile("${path.module}/templates/cloud-init-fedora.yaml.tftpl", {
#     hostname        = "okd-master-02"
#     role            = "master"
#     internal_domain = local.internal_domain
#     aws_region      = var.aws_region
#   })
# }
#
# module "okd_master_03" { ... }
#
# module "okd_worker_02" {
#   source = "./modules/ec2"
#
#   name                   = "OKD-Worker-02"
#   role                   = "Worker"
#   os                     = "Fedora"
#   ami_id                 = var.fedora_ami_id
#   instance_type          = var.worker_instance_type
#   subnet_id              = module.vpc.private_subnet_ids[0]
#   vpc_security_group_ids = [module.security_groups.worker_sg_id]
#   key_name               = module.key_pair.key_name
#   associate_public_ip    = false
#   root_volume_size       = var.node_root_volume_size
#   iam_instance_profile   = module.instance_profile.instance_profile_name
#   tags                   = local.common_tags
#
#   user_data = templatefile("${path.module}/templates/cloud-init-fedora.yaml.tftpl", {
#     hostname        = "okd-worker-02"
#     role            = "worker"
#     internal_domain = local.internal_domain
#     aws_region      = var.aws_region
#   })
# }
#
# module "okd_worker_03" { ... }
