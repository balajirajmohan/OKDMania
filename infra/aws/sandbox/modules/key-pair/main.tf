# ===========================================================================
# EC2 key pair  (spec section 7)
# ===========================================================================
# We import an EXISTING locally-generated public key. AWS stores only the
# public half; the private key (okd-project.pem) stays on your machine, chmod
# 400, gitignored, and NEVER enters Terraform state or output.
#
# Why not tls_private_key + local_file?
#   The `tls_private_key` resource writes the generated PRIVATE key into
#   terraform.tfstate in cleartext. Even with a local_file export and tight
#   permissions, the secret is now in state (and any state backup / remote
#   backend). The spec (section 7) explicitly prefers "the private key exists
#   locally while AWS stores only the public key" - which is exactly this.
#
# Workflow:
#   1. ./infra/aws/sandbox/scripts/generate-key.sh
#   2. terraform apply   (uploads okd-project.pem.pub)
# ===========================================================================

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = trimspace(file(var.public_key_path))

  tags = merge(var.tags, { Name = var.key_name })
}
