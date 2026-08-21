module "jenkins" {
  source = "../../helpers/terraform-modules//aws_ec2"

  name                        = var.jenkins_instance_name
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.jenkins_instance_type
  subnet_id                   = module.subnet.subnet_ids[0]
  security_group_ids          = [module.jenkins_sg.security_group_id]
  associate_public_ip_address = true
  key_name                    = data.terraform_remote_state.keypair.outputs.key_name
  user_data                   = file("${path.module}/user_data/jenkins_install.sh")
}

module "deploy_target" {
  source = "../../helpers/terraform-modules//aws_ec2"

  name                        = var.deploy_instance_name
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.deploy_instance_type
  subnet_id                   = module.subnet.subnet_ids[0]
  security_group_ids          = [module.deploy_sg.security_group_id]
  associate_public_ip_address = true
  key_name                    = data.terraform_remote_state.keypair.outputs.key_name
  user_data                   = file("${path.module}/user_data/deploy_target_install.sh")
}
