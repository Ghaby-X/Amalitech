#!/bin/bash
set -euo pipefail

dnf update -y
dnf install -y docker git
systemctl enable --now docker
usermod -aG docker ec2-user

# docker compose v2 plugin
mkdir -p /usr/local/lib/docker/cli-plugins
curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

mkdir -p /opt/monitoring/prometheus
mkdir -p /opt/monitoring/alertmanager
mkdir -p /opt/monitoring/grafana/provisioning/datasources
mkdir -p /opt/monitoring/grafana/provisioning/dashboards
mkdir -p /opt/monitoring/grafana/dashboards

cat <<'EOF' > /opt/monitoring/docker-compose.yml
${compose_yml}
EOF

cat <<'EOF' > /opt/monitoring/prometheus/prometheus.yml
${prometheus_yml}
EOF

cat <<'EOF' > /opt/monitoring/prometheus/alert_rules.yml
${alert_rules_yml}
EOF

cat <<'EOF' > /opt/monitoring/alertmanager/alertmanager.yml
${alertmanager_yml}
EOF

cat <<'EOF' > /opt/monitoring/grafana/provisioning/datasources/datasource.yml
${grafana_datasource_yml}
EOF

cat <<'EOF' > /opt/monitoring/grafana/provisioning/dashboards/dashboard.yml
${grafana_dashboard_provider_yml}
EOF

cat <<'EOF' > /opt/monitoring/grafana/dashboards/app-observability.json
${grafana_dashboard_json}
EOF

cd /opt/monitoring
docker compose up -d
