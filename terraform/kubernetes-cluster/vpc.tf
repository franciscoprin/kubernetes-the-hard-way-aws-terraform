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

# Default security rules for the VPC
#  ( It is a firewall for all the resources inside of the VPC )
resource "aws_security_group" "k8s_sg" {
  vpc_id = aws_vpc.k8s_vpc.id

  # All protocols are allowed for the specified private CIDR blocks
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.1.0.0/16", "10.201.0.0/16"]
  }

  # TCP protocol is allowed for the specified ports
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # ICMP protocol is allowed for all IPs in all the Ports.
  #  for network troubleshooting and diagnostic purposes, 
  #  such as ping requests.
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an internet gateway for bidirectional communication
# between the k8s EC2 cluster in subnet and the internet.
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "kubernetes"
  }
}

# Create a route table that will control the traffic flow of the k8s EC2 cluster.
resource "aws_route_table" "k8s_route_table" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "kubernetes"
  }
}

# Create a route for the internet gateway
# Allow all the instances in the subnet to communicate with the internet.
resource "aws_route" "k8s_internet_gateway_route" {
  route_table_id         = aws_route_table.k8s_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.k8s_igw.id
}

# Associate the route table with the subnet
resource "aws_route_table_association" "k8s_route_table_association" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.k8s_route_table.id
}

# Create a load balancer in the same subnet where the K8S EC2 cluster will be created:
resource "aws_lb" "lb_k8s" {
  name               = "kubernetes"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.k8s_subnet.id]

  tags = {
    Name = "kubernetes"
  }
}

# Create a target group to which the load balancer will balance traffic:
resource "aws_lb_target_group" "target_group_k8s" {
  name        = "kubernetes"
  port        = 6443
  protocol    = "TCP"
  vpc_id      = aws_vpc.k8s_vpc.id
  target_type = "ip"

  health_check {
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Attach worker nodes EC2 instances to the target group:
resource "aws_lb_target_group_attachment" "kubernetes" {
  count            = 3
  target_group_arn = aws_lb_target_group.target_group_k8s.arn
  target_id        = "10.1.1.1${count.index}"
  port             = 6443
}

# Specify the port and protocol on which the load balancer will listen to redirect traffic to the workers nodes:
resource "aws_lb_listener" "kubernetes" {
  load_balancer_arn = aws_lb.lb_k8s.arn
  protocol          = "TCP"
  port              = "433"

  default_action {
    target_group_arn = aws_lb_target_group.target_group_k8s.arn
    type             = "forward"
  }
}
