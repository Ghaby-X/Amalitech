module "app_sg" {
  source = "../../helpers/terraform-modules//aws_security_group"

  name        = "lab-dom08-app-sg"
  description = "App host - SSH only via the EC2 Instance Connect Endpoint, app port public for verification, metrics/node-exporter reachable from the monitoring host only"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    ssh_via_instance_connect = {
      description                  = "SSH via the EC2 Instance Connect Endpoint - no personal IP is ever opened"
      ip_protocol                  = "tcp"
      from_port                    = 22
      to_port                      = 22
      referenced_security_group_id = module.eice_sg.security_group_id
    }
    app = {
      description = "App port, for verifying accessibility and browsing the dashboard"
      ip_protocol = "tcp"
      from_port   = var.app_port
      to_port     = var.app_port
      cidr_ipv4   = var.app_allowed_cidr
    }
    node_exporter_from_monitoring = {
      description                  = "Node Exporter, scraped by Prometheus on the monitoring host"
      ip_protocol                  = "tcp"
      from_port                    = var.node_exporter_port
      to_port                      = var.node_exporter_port
      referenced_security_group_id = module.monitoring_sg.security_group_id
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

module "monitoring_sg" {
  source = "../../helpers/terraform-modules//aws_security_group"

  name        = "lab-dom08-monitoring-sg"
  description = "Monitoring host - SSH only via the EC2 Instance Connect Endpoint, Prometheus/Grafana UIs from an allowed IP only"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = {
    ssh_via_instance_connect = {
      description                  = "SSH via the EC2 Instance Connect Endpoint - no personal IP is ever opened"
      ip_protocol                  = "tcp"
      from_port                    = 22
      to_port                      = 22
      referenced_security_group_id = module.eice_sg.security_group_id
    }
    prometheus_ui = {
      description = "Prometheus web UI from allowed IP"
      ip_protocol = "tcp"
      from_port   = 9090
      to_port     = 9090
      cidr_ipv4   = var.admin_allowed_cidr
    }
    grafana_ui = {
      description = "Grafana web UI from allowed IP"
      ip_protocol = "tcp"
      from_port   = 3001
      to_port     = 3001
      cidr_ipv4   = var.admin_allowed_cidr
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
