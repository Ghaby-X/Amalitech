module "app" {
  source = "../../helpers/terraform-modules//aws_ec2"

  name                        = var.app_instance_name
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.app_instance_type
  subnet_id                   = module.subnet.subnet_ids[0]
  security_group_ids          = [module.app_sg.security_group_id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.app_logs_profile.name

  user_data = templatefile("${path.module}/user_data/app_install.sh.tpl", {
    app_repo_url   = var.app_repo_url
    app_repo_ref   = var.app_repo_ref
    app_port       = var.app_port
    aws_region     = var.region
    log_group_name = var.app_log_group_name
  })
}

module "monitoring" {
  source = "../../helpers/terraform-modules//aws_ec2"

  name                        = var.monitoring_instance_name
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.monitoring_instance_type
  subnet_id                   = module.subnet.subnet_ids[0]
  security_group_ids          = [module.monitoring_sg.security_group_id]
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data/monitoring_install.sh.tpl", {
    compose_yml = file("${path.module}/../docker-compose.monitoring.yml")

    prometheus_yml = templatefile("${path.module}/../prometheus/prometheus.yml.tpl", {
      app_private_ip     = module.app.private_ip
      app_port           = var.app_port
      node_exporter_port = var.node_exporter_port
    })

    alert_rules_yml = file("${path.module}/../prometheus/alert_rules.yml")

    grafana_datasource_yml         = file("${path.module}/../grafana/provisioning/datasources/datasource.yml")
    grafana_dashboard_provider_yml = file("${path.module}/../grafana/provisioning/dashboards/dashboard.yml")
    grafana_dashboard_json         = file("${path.module}/../grafana/dashboards/app-observability.json")
  })
}
