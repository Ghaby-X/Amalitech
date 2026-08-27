global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - /etc/prometheus/alert_rules.yml

scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name: "server_details_app"
    metrics_path: /metrics
    static_configs:
      - targets: ["${app_private_ip}:${app_port}"]
        labels:
          instance_role: "app"

  - job_name: "node_exporter"
    static_configs:
      - targets: ["${app_private_ip}:${node_exporter_port}"]
        labels:
          instance_role: "app"
