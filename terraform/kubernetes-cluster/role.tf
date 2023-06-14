resource "aws_iam_role" "k8s_nodes" {
  name = "k8s-nodes-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "ec2:ResourceTag/Type" = "kubernetes-node"
          }
        }
      }
    ]
  })
}
