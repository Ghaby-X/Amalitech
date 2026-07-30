module "keypair" {
  source = "../terraform-modules//aws_key_pair"

  key_name         = var.key_name
  private_key_path = var.private_key_path

  tags = {
    Name = var.key_name
  }
}
