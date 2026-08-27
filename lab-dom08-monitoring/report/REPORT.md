# Project 6: Full Observability & Security Solution — Report

**Author:** Gabriel Anyaele
**Stack:** Prometheus, Grafana, AWS CloudWatch, CloudTrail, GuardDuty
**Repo:** `lab-dom08-monitoring/` (this repo) · app: [server_details](https://github.com/Ghaby-X/server_details), branch `feature/prometheus-metrics`

> Sections marked **[fill in after provisioning]** need the real numbers/screenshots from a live run - see `README.md`'s verification steps and screenshot checklist.

## 1. What was built

The `server_details` app from the CI/CD lab already ran as a container; it did not expose any metrics. This project added a zero-dependency `GET /metrics` endpoint (Prometheus text format: `http_requests_total` counter by method/route/status, `http_request_duration_seconds` histogram, process gauges) and a `GET /api/fail` diagnostic route for exercising error-rate alerting, then stood up a full stack around it:

- **Prometheus** on a dedicated EC2 host, scraping the app's `/metrics` and a **Node Exporter** sidecar on the app host for OS-level metrics (CPU, memory).
- **Grafana**, provisioned (not click-ops) with a Prometheus datasource and a dashboard covering requests/sec, p50/p95/p99 latency, and error rate, alongside host CPU/memory.
- An **alerting rule** (`HighErrorRate`) evaluated by Prometheus itself: 5xx responses over 5% of traffic for 30 seconds. Kept in Prometheus rather than bolted onto a separate Alertmanager, since Grafana's Prometheus datasource surfaces the same rule under its own Alerting UI (`manageAlerts: true`) - one rule, two places to see it fire, no extra moving part to run and maintain.
- **CloudWatch Logs** via the Docker `awslogs` log driver on the app container - no sidecar agent, no polling; the container's stdout/stderr streams to `/lab-dom08/app` as it's written.
- **CloudTrail**, multi-region, log file validation on, delivering to both an **encrypted** (SSE-S3), **lifecycled** (Standard-IA at 30 days → Glacier at 90 → expired at 365) S3 bucket, and to a CloudWatch Logs group for near-real-time querying.
- **GuardDuty**, a single regional detector watching account activity for threats.
- SSH to either instance goes only through an **EC2 Instance Connect Endpoint** - no personal IP is ever opened in a security group, which was a deliberate tightening beyond what the lab brief asked for.

## 2. Why these choices

**Prometheus metrics were hand-rolled, not a client library.** The app is intentionally zero-runtime-dependency (a course constraint from the CI/CD lab); pulling in `prom-client` would have broken that invariant for a ~70-line collector. The histogram buckets (5ms-10s) were sized for a Node.js app serving JSON from memory and static files from disk - sub-second by a wide margin - so the interesting resolution sits below 250ms.

**Two EC2 instances, not one.** Colocating Prometheus/Grafana with the thing they monitor is a common shortcut, but it hides a real failure mode: if the app host goes down, a colocated Prometheus goes down with it and can't alert on the outage. Splitting them means Prometheus's own `up{job="server_details_app"} == 0` (the `AppTargetDown` rule) is meaningful.

**Error-rate threshold and window.** The brief asks for >5% - a threshold chosen to sit clearly above normal noise (occasional 404s from bots/scanners) but low enough that a real incident trips it fast. A 2-minute `rate()` window with a 30-second `for` was chosen for **demo speed**: with default `scrape_interval: 15s`, a 2-minute window has enough samples to be a real rate rather than noise, while 30s keeps the demo loop (see README) under a minute from "start sending errors" to "alert fires." In a production system with steadier baseline traffic, a 5-minute window with a 2-5 minute `for` is the more defensible choice - it trades demo speed for resistance to brief blips.

**CloudTrail → both S3 and CloudWatch Logs.** S3 is the durable, cheap, lifecycled record required for audit/compliance; CloudWatch Logs is for the operational case - alerting on specific API calls or searching recent activity with Logs Insights without touching S3 at all. Neither alone covers both needs well.

**No open SSH CIDR.** The lab brief doesn't ask for this, but hardcoding "my IP" into a security group is exactly the kind of drift that outlives its usefulness (home IP changes, a laptop on a different network, a teammate who needs access). An EC2 Instance Connect Endpoint removes the tradeoff entirely - SSH access requires an IAM principal, not network position, and nothing port-22-shaped is reachable from the internet on either instance.

## 3. Verification — results

**[fill in after provisioning]**

| Check | Result | Evidence |
|---|---|---|
| Prometheus targets UP (app + node_exporter) | | `screenshots/001_prometheus_targets.png` |
| Grafana dashboard live with real traffic | | `screenshots/002_grafana_dashboard.png` |
| `HighErrorRate` fired under induced load | | `screenshots/003_prometheus_alert_firing.png`, `004_grafana_alert_view.png` |
| App container logs visible in CloudWatch | | `screenshots/005_cloudwatch_log_group.png` |
| CloudTrail trail logging, S3 + CloudWatch Logs destinations configured | | `screenshots/006_cloudtrail_trail.png` |
| S3 bucket encrypted + lifecycle rule present | | `screenshots/007_cloudtrail_s3_bucket.png` |
| GuardDuty findings visible (sample or organic) | | `screenshots/008_guardduty_findings.png` |

Observed p95 latency under load: **[X] ms**. Observed peak error rate during the `/api/fail` load test: **[X]%**, alert transitioned Pending → Firing after **[X] seconds**, matching the 30s `for` clause plus one scrape interval of detection lag.

## 4. Insights

**[fill in after provisioning - replace with what the data actually showed]**

Talking points to develop once real data is in hand:
- How closely did induced error rate/latency match what the dashboard reported, and how much lag was there between "traffic sent" and "panel updated" (bounded by `scrape_interval` + Grafana's own refresh)?
- Did `AppTargetDown` ever false-positive during the app container's build/startup window, and does that suggest the `for` duration needs adjusting?
- What did CloudTrail's Event history show for the `terraform apply` itself - is every resource this stack created individually attributable to an IAM principal and a timestamp?
- Did GuardDuty need sample findings, or did normal lab traffic (SSH via Instance Connect, S3/CloudWatch API calls) produce anything organically?

## 5. Cleanup

`terraform destroy` after verification (see README) removes both EC2 instances, the VPC, the Instance Connect Endpoint, CloudTrail, both CloudWatch log groups, and the GuardDuty detector. The S3 bucket is intentionally not force-deleted - emptied manually first if it should also go. **[confirm: destroy completed at Y, verified no lab-dom08 resources remain in the console]**
