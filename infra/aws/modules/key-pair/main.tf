# ===========================================================================
# EC2 key pair  (spec section 5)
# ===========================================================================
# References the EXISTING "OKD-Project" key pair already present in this AWS
# account. We never create a key pair here - AWS holds only the public half
# of whatever key that account resource represents; the matching private key
# is managed out-of-band by whoever administers OKD-Project access.
# ===========================================================================

data "aws_key_pair" "this" {
  key_name = var.key_name
}
