# ===========================================================================
# Security groups  (spec section 8)
# ===========================================================================
# One SG per role: master, worker, ansible, runner.
#
# Design:
#   * SSH (22) is allowed ONLY from var.admin_cidrs on every SG. Never 0.0.0.0/0.
#   * The OKD "cluster fabric" (etcd, kubelet, machine-config 22623, DNS,
#     controller/scheduler, SDN/OVN overlay - VXLAN 4789, Geneve 6081, IPsec,
#     NodePorts, host services) is a large, version-sensitive set of ports.
#     Rather than enumerate and drift from the docs, we allow ALL traffic
#     between the master and worker SGs (and from the ansible SG). This mirrors
#     what the upstream OpenShift AWS CloudFormation templates do for the
#     control-plane / compute security groups.
#   * Only the genuinely external ports are enumerated and documented:
#       - 22    SSH            <- admin_cidrs
#       - 6443  Kubernetes API <- cluster_api_cidrs (default admin_cidrs)
#       - 80    HTTP router    <- apps_ingress_cidrs (default internet)
#       - 443   HTTPS router   <- apps_ingress_cidrs (default internet)
#       - ICMP  path MTU / ping <- vpc_cidr
#
# See infra/aws/sandbox/README.md "Security groups & ports" for the full map
# and which ports face the internet and why.
# ===========================================================================

locals {
  api_cidrs = length(var.cluster_api_cidrs) > 0 ? var.cluster_api_cidrs : var.admin_cidrs
}

# ---------------------------------------------------------------------------
# Security group shells
# ---------------------------------------------------------------------------
# name_prefix (not name) so `create_before_destroy` can swap a group without a
# name collision. The stable identifier is the Name tag.
resource "aws_security_group" "master" {
  name_prefix = "${var.name_prefix}-master-"
  description = "OKD master / control-plane node"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-master", Role = "master" })

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "worker" {
  name_prefix = "${var.name_prefix}-worker-"
  description = "OKD worker / compute node"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-worker", Role = "worker" })

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "ansible" {
  name_prefix = "${var.name_prefix}-ansible-"
  description = "Ansible control node"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-ansible", Role = "ansible" })

  lifecycle { create_before_destroy = true }
}

resource "aws_security_group" "runner" {
  name_prefix = "${var.name_prefix}-runner-"
  description = "CI/CD runner host"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-runner", Role = "runner" })

  lifecycle { create_before_destroy = true }
}

# ---------------------------------------------------------------------------
# SSH (22) - admin_cidrs only, all four roles
# ---------------------------------------------------------------------------
locals {
  ssh_targets = {
    master  = aws_security_group.master.id
    worker  = aws_security_group.worker.id
    ansible = aws_security_group.ansible.id
    runner  = aws_security_group.runner.id
  }
  # cartesian product of {role} x {admin cidr}
  ssh_rules = merge([
    for role, sg_id in local.ssh_targets : {
      for cidr in var.admin_cidrs :
      "${role}-${cidr}" => { sg_id = sg_id, cidr = cidr }
    }
  ]...)
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  for_each = local.ssh_rules

  security_group_id = each.value.sg_id
  description       = "SSH from trusted admin CIDR"
  cidr_ipv4         = each.value.cidr
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

# ---------------------------------------------------------------------------
# Cluster fabric - allow everything between master <-> worker <-> (from) ansible
# ---------------------------------------------------------------------------
# master: from master (self), worker, ansible
resource "aws_vpc_security_group_ingress_rule" "master_from_master" {
  security_group_id            = aws_security_group.master.id
  description                  = "All control-plane/etcd/SDN traffic from other masters"
  referenced_security_group_id = aws_security_group.master.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "master_from_worker" {
  security_group_id            = aws_security_group.master.id
  description                  = "All kubelet/SDN/NodePort traffic from workers"
  referenced_security_group_id = aws_security_group.worker.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "master_from_ansible" {
  security_group_id            = aws_security_group.master.id
  description                  = "Ansible control node - config management over SSH and API"
  referenced_security_group_id = aws_security_group.ansible.id
  ip_protocol                  = "-1"
}

# worker: from master, worker (self), ansible
resource "aws_vpc_security_group_ingress_rule" "worker_from_master" {
  security_group_id            = aws_security_group.worker.id
  description                  = "All control-plane to node traffic (machine-config, kubelet, SDN)"
  referenced_security_group_id = aws_security_group.master.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "worker_from_worker" {
  security_group_id            = aws_security_group.worker.id
  description                  = "All node-to-node traffic between workers (SDN overlay, NodePorts)"
  referenced_security_group_id = aws_security_group.worker.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "worker_from_ansible" {
  security_group_id            = aws_security_group.worker.id
  description                  = "Ansible control node - config management"
  referenced_security_group_id = aws_security_group.ansible.id
  ip_protocol                  = "-1"
}

# ---------------------------------------------------------------------------
# Kubernetes / OKD API - 6443 on the master
# ---------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "master_api" {
  for_each = toset(local.api_cidrs)

  security_group_id = aws_security_group.master.id
  description       = "Kubernetes/OKD API server"
  cidr_ipv4         = each.value
  from_port         = 6443
  to_port           = 6443
  ip_protocol       = "tcp"
}

# ---------------------------------------------------------------------------
# Application HTTP/HTTPS - the OpenShift router runs on worker nodes; we also
# open it on the master to support a single-node layout.
# ---------------------------------------------------------------------------
locals {
  http_targets = {
    master = aws_security_group.master.id
    worker = aws_security_group.worker.id
  }
  http_rules = merge([
    for role, sg_id in local.http_targets : {
      for combo in setproduct(["80", "443"], var.apps_ingress_cidrs) :
      "${role}-${combo[0]}-${combo[1]}" => {
        sg_id = sg_id
        port  = tonumber(combo[0])
        cidr  = combo[1]
      }
    }
  ]...)
}

resource "aws_vpc_security_group_ingress_rule" "apps_http" {
  for_each = local.http_rules

  security_group_id = each.value.sg_id
  description       = "Application ingress (OpenShift router / demo apps)"
  cidr_ipv4         = each.value.cidr
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "nodeport_from_apps" {
  for_each = var.enable_nodeport_from_apps ? toset(var.apps_ingress_cidrs) : toset([])

  security_group_id = aws_security_group.worker.id
  description       = "NodePort range from apps ingress CIDRs"
  cidr_ipv4         = each.value
  from_port         = 30000
  to_port           = 32767
  ip_protocol       = "tcp"
}

# ---------------------------------------------------------------------------
# ICMP within the VPC (path-MTU discovery, ping for debugging)
# ---------------------------------------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "icmp" {
  for_each = local.ssh_targets

  security_group_id = each.value
  description       = "ICMP from within the VPC"
  cidr_ipv4         = var.vpc_cidr
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
}

# ---------------------------------------------------------------------------
# Egress - allow all outbound from every SG.
# The nodes are in public subnets with no NAT; they need direct internet for
# package installs, container image pulls, and AWS API calls.
# ---------------------------------------------------------------------------
resource "aws_vpc_security_group_egress_rule" "all" {
  for_each = local.ssh_targets

  security_group_id = each.value
  description       = "Allow all outbound"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
