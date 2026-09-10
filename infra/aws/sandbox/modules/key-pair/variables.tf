variable "key_name" {
  description = "Name of the EC2 key pair to create in AWS."
  type        = string
  default     = "okd-project"
}

variable "public_key_path" {
  description = <<-EOT
    Path to the PUBLIC key file to upload to AWS (e.g. okd-project.pem.pub),
    relative to the calling module. Generate the pair first with
    scripts/generate-key.sh - it writes okd-project.pem (private, chmod 400)
    and okd-project.pem.pub (public). Only the public key is sent to AWS; the
    private key never touches Terraform.
  EOT
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
