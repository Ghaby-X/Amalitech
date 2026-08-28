route:
  receiver: default
  group_by: ["alertname"]
  group_wait: 10s
  group_interval: 5m
  repeat_interval: 3h

receivers:
%{ if slack_webhook_url != "" ~}
  - name: default
    slack_configs:
      - api_url: "${slack_webhook_url}"
%{ if slack_channel != "" ~}
        channel: "${slack_channel}"
%{ endif ~}
        send_resolved: true
        title: "{{ .GroupLabels.alertname }}"
        text: "{{ range .Alerts }}{{ .Annotations.description }}\n{{ end }}"
%{ else ~}
  # No slack_webhook_url set (see terraform.tfvars) - this receiver has no
  # integrations, so Alertmanager still starts and routes alerts here, it
  # just doesn't notify anyone. Set the variable and re-apply to enable
  # Slack delivery.
  - name: default
%{ endif ~}
