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

# key pair is shared across labs; managed in helpers/keypair
data "terraform_remote_state" "keypair" {
  backend = "s3"

  config = {
    bucket = "terraform-backend-eu-west-1-55zz0s"
    key    = "helpers/keypair/statefile"
    region = "eu-west-1"
  }
}
