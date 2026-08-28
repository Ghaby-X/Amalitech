global:
  scrape_interval: 15s
  evaluation_interval: 15s

# No rule_files / alerting block here - the error-rate alert is configured
# directly in Grafana (Alerting -> Alert rules, via the Prometheus
# datasource), not as a Prometheus-evaluated rule. See README.

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "server_details_app"
    metrics_path: /metrics
    ec2_sd_configs:
      - region: ${aws_region}
        port: ${app_port}
        filters:
          - name: tag:Name
            values: ["${app_instance_name}"]
          - name: vpc-id
            values: ["${vpc_id}"]
          - name: instance-state-name
            values: ["running"]
    relabel_configs:
      - target_label: instance_role
        replacement: app

  - job_name: "node_exporter"
    ec2_sd_configs:
      - region: ${aws_region}
        port: ${node_exporter_port}
        filters:
          - name: tag:Name
            values: ["${app_instance_name}"]
          - name: vpc-id
            values: ["${vpc_id}"]
          - name: instance-state-name
            values: ["running"]
    relabel_configs:
      - target_label: instance_role
        replacement: app
