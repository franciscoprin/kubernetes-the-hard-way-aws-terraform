# Create the VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.1.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "kubernetes-the-hard-way"
  }
}

# Create the subnet in which the EC2 cluster will be hosted.
resource "aws_subnet" "k8s_subnet" {
  vpc_id     = aws_vpc.k8s_vpc.id
  cidr_block = "10.1.1.0/24"

  tags = {
    Name = "kubernetes-the-hard-way"
  }
}
