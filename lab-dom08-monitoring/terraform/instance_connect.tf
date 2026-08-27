# EC2 Instance Connect Endpoint - lets you SSH via `aws ec2-instance-connect
# ssh` (ephemeral keys pushed over the AWS API, tunnelled privately into the
# VPC) with no inbound SSH CIDR open on either instance's security group.

module "eice_sg" {
  source = "../../helpers/terraform-modules//aws_security_group"

  name        = "lab-dom08-eice-sg"
  description = "EC2 Instance Connect Endpoint - no inbound needed, egress to instances on 22"
  vpc_id      = module.vpc.vpc_id

  egress_rules = {
    ssh_to_vpc = {
      description = "SSH to instances in this VPC"
      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_ipv4   = var.vpc_cidr_block
    }
  }
}

resource "aws_ec2_instance_connect_endpoint" "this" {
  subnet_id          = module.subnet.subnet_ids[0]
  security_group_ids = [module.eice_sg.security_group_id]

  tags = {
    Name = "lab-dom08-eice"
  }
}
