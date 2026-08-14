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

module "ec2" {
  source = "../../../helpers/terraform-modules//aws_ec2"

  name                        = var.instance_name
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = module.subnet.subnet_ids[0]
  security_group_ids          = [module.security_group.security_group_id]
  associate_public_ip_address = true
  key_name                    = data.terraform_remote_state.keypair.outputs.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_secrets_profile.name
}
