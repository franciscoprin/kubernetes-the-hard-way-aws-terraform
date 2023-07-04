# Craete a TLS/SSL certificate:
resource "tls_private_key" "kubernetes" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a key pair to enable SSH access to Kubernetes nodes later on:
resource "aws_key_pair" "kubernetes" {
  key_name   = "kubernetes"
  public_key = tls_private_key.kubernetes.public_key_openssh
}

# Upload the SSH key to the bucket so it can be used to access to the Kubernetes nodes.
locals {
  ssh_keys = {
    private_key = tls_private_key.kubernetes.private_key_pem
    public_key  = tls_private_key.kubernetes.public_key_openssh
  }
}

resource "aws_s3_bucket_object" "ssh_keys" {
  for_each = local.ssh_keys
  bucket   = aws_s3_bucket.kube_certs.id
  key      = "ssh-keys/${each.key}.pem"

  content = each.value
}

