locals {
  bucket_name    = "spoton-kubernetes-the-hard-way"
  s3_prefix_path = "kube-certs"
  is_planning    = terraform.workspace == "default"
}

resource "aws_s3_bucket" "kube_certs" {
  bucket = local.bucket_name
  acl    = "private"

  tags = {
    Name        = "Kubernetes CA Files"
    Environment = "test"
  }
}

resource "aws_s3_bucket_policy" "k8s_nodes" {
  bucket = aws_s3_bucket.kube_certs.bucket

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.k8s_nodes.arn
        }
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.kube_certs.arn}",
          "${aws_s3_bucket.kube_certs.arn}/*"
        ]
      }
    ]
  })
}

data "shell_script" "k8s_secrets" {
  lifecycle_commands {
    read = <<-EOF
      bash ${path.module}/kube-certs-scripts/setup-kube-encryption-key.sh
    EOF
  }

  environment = {
    //changes to one of these will trigger an update
    bucket_name    = aws_s3_bucket_policy.k8s_nodes.bucket
    s3_prefix_path = local.s3_prefix_path
    expired_delta_seconds = var.delta_cert_expiration_seconds
  }
}

resource "shell_script" "create_and_upload_kube_certs" {

  depends_on = [
    aws_s3_bucket.kube_certs,
    aws_lb.lb_k8s,
    data.shell_script.k8s_secrets,
  ]

#   triggers = {
#     S3_PREFIX_PATH     = local.s3_prefix_path
#     BUCKET_NAME        = aws_s3_bucket_policy.k8s_nodes.bucket
#     K8S_PUBLIC_ADDRESS = aws_lb.lb_k8s.dns_name
#     ENCRYPTION_KEY     = base64encode(data.shell_script.k8s_secrets.output["encryption_key"])
#   }

  lifecycle_commands {
      create = <<-EOD
        bash ${path.module}/kube-certs-scripts/setup-kube-certs.sh \
          $S3_PREFIX_PATH \
          $BUCKET_NAME \
          $K8S_PUBLIC_ADDRESS \
          $ENCRYPTION_KEY
      EOD

      update = <<-EOD
        bash ${path.module}/kube-certs-scripts/setup-kube-certs.sh \
          $S3_PREFIX_PATH \
          $BUCKET_NAME \
          $K8S_PUBLIC_ADDRESS \
          $ENCRYPTION_KEY
      EOD

      delete = <<-EOD
        aws s3 rm --recursive s3://$BUCKET_NAME/$S3_PREFIX_PATH/
      EOD

      # Last JSON object written to stdout in read is taken to be state.
      read   = <<-EOD
        output=$(aws s3api list-objects-v2 \
          --bucket "$BUCKET_NAME" \
          --prefix "$S3_PREFIX_PATH" \
          --query 'sort_by(Contents, &Key)[].{Key: Key, LastModified: LastModified}' \
          --output json 2>/dev/null || echo "[]" | jq -r '@json' | jq 'sort_by(.Key)')

        echo "{\"output\": $output}"
      EOD
  }

  environment = {
    S3_PREFIX_PATH = local.s3_prefix_path
    BUCKET_NAME    = aws_s3_bucket_policy.k8s_nodes.bucket
  }

  sensitive_environment = {
    ENCRYPTION_KEY     = base64encode(data.shell_script.k8s_secrets.output["encryption_key"])
    K8S_PUBLIC_ADDRESS = aws_lb.lb_k8s.dns_name
  }
}

resource "aws_ssm_parameter" "encryption_key" {
  depends_on = [data.shell_script.k8s_secrets]
  name       = "/k8s-the-hard-way/encryption_key"
  type       = "SecureString"
  value      = data.shell_script.k8s_secrets.output["encryption_key"]
}
