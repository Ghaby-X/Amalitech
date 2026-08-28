#!/bin/bash
set -euo pipefail

dnf update -y
dnf install -y docker git
systemctl enable --now docker
usermod -aG docker ec2-user

# Build the app from the metrics-enabled branch (see var.app_repo_ref)
git clone --branch "${app_repo_ref}" --depth 1 "${app_repo_url}" /opt/app
cd /opt/app
docker build -t server-details:metrics .

# Instance ID (IMDSv2) - used to name the log stream, so replacing this
# instance (terraform apply -replace=...) starts a fresh stream instead of
# mixing a new instance's logs into an old, now-terminated instance's stream.
IMDS_TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

# App container - logs streamed to CloudWatch Logs via the awslogs driver.
# Requires the instance's IAM role to allow logs:CreateLogStream/PutLogEvents
# on ${log_group_name}.
docker run -d \
  --name app \
  --restart unless-stopped \
  -p ${app_port}:${app_port} \
  -e PORT=${app_port} \
  --log-driver awslogs \
  --log-opt awslogs-region=${aws_region} \
  --log-opt awslogs-group=${log_group_name} \
  --log-opt awslogs-create-group=true \
  --log-opt awslogs-stream="app/$INSTANCE_ID" \
  server-details:metrics

# Node Exporter - host metrics for Prometheus, restricted to the monitoring
# host's security group (see terraform/security_groups.tf).
docker run -d \
  --name node-exporter \
  --restart unless-stopped \
  --net host \
  --pid host \
  -v "/:/host:ro,rslave" \
  prom/node-exporter:v1.8.2 \
  --path.rootfs=/host
