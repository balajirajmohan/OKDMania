#!/usr/bin/env bash
# ===========================================================================
# generate-key.sh  (spec section 7)
# ===========================================================================
# Generates the SSH key pair used for every sandbox instance:
#   okd-project.pem      private key, chmod 400, NEVER committed
#   okd-project.pem.pub  public key, uploaded to AWS by Terraform
#
# The private key stays on your machine. Terraform only ever reads the .pub.
# ===========================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_NAME="${1:-okd-project}"
KEY_PATH="${SCRIPT_DIR}/${KEY_NAME}.pem"
PUB_PATH="${KEY_PATH}.pub"

if [[ -e "${KEY_PATH}" || -e "${PUB_PATH}" ]]; then
  echo "ERROR: ${KEY_PATH} or ${PUB_PATH} already exists."
  echo "Refusing to overwrite an existing key. Delete them by hand if you're sure."
  exit 1
fi

# ed25519: smaller, faster, modern. RSA also fine if your tooling needs it:
#   ssh-keygen -t rsa -b 4096 -N '' -C "${KEY_NAME}" -f "${KEY_PATH}"
ssh-keygen -t ed25519 -N '' -C "${KEY_NAME}" -f "${KEY_PATH}"

chmod 400 "${KEY_PATH}"
chmod 444 "${PUB_PATH}"

echo
echo "Created:"
echo "  ${KEY_PATH}      (private, 0400 - keep this safe, it is gitignored)"
echo "  ${PUB_PATH}  (public  - Terraform uploads this)"
echo
echo "Next:"
echo "  1. cp '${KEY_PATH}' ~/.ssh/${KEY_NAME}.pem   # so 'ssh -i' and Ansible find it"
echo "  2. cd ../environments/sandbox && terraform apply"
echo
echo "To also use it from the okd-ansible box, scp the .pem there:"
echo "  scp -i ~/.ssh/${KEY_NAME}.pem ~/.ssh/${KEY_NAME}.pem ubuntu@<ansible_public_ip>:~/.ssh/"
