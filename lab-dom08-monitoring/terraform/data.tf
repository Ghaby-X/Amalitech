# find the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_caller_identity" "current" {}

# AWS-managed prefix list of the source ranges the EC2 console's browser-
# based "Connect using EC2 Instance Connect"
data "aws_ec2_managed_prefix_list" "ec2_instance_connect" {
  name = "com.amazonaws.${var.region}.ec2-instance-connect"
}
