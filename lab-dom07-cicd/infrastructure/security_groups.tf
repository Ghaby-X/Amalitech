module "jenkins_sg" {
  source = "../../helpers/terraform-modules//aws_security_group"

  name        = "lab-dom07-jenkins-sg"
  description = "Jenkins host - SSH and web UI from an allowed IP only"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    ssh = {
      description = "SSH from allowed IP"
      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_ipv4   = var.ssh_allowed_cidr
    }
    jenkins_ui = {
      description = "Jenkins web UI from allowed IP"
      ip_protocol = "tcp"
      from_port   = 8080
      to_port     = 8080
      cidr_ipv4   = coalesce(var.jenkins_ui_allowed_cidr, var.ssh_allowed_cidr)
    }
  }

  egress_rules = {
    all = {
      description = "allow all outbound"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}

module "deploy_sg" {
  source = "../../helpers/terraform-modules//aws_security_group"

  name        = "lab-dom07-deploy-sg"
  description = "Deploy target - SSH from allowed IP and from Jenkins, app port public"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    ssh_admin = {
      description = "SSH from allowed IP"
      ip_protocol = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_ipv4   = var.ssh_allowed_cidr
    }
    ssh_jenkins = {
      description                  = "SSH from the Jenkins host, for the pipeline Deploy stage"
      ip_protocol                  = "tcp"
      from_port                    = 22
      to_port                      = 22
      referenced_security_group_id = module.jenkins_sg.security_group_id
    }
    app = {
      description = "App port, for verifying accessibility"
      ip_protocol = "tcp"
      from_port   = var.app_port
      to_port     = var.app_port
      cidr_ipv4   = var.app_allowed_cidr
    }
  }

  egress_rules = {
    all = {
      description = "allow all outbound"
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
}
