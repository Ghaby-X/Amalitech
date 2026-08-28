# Project 6: Full Observability & Security Solution: Report

**Author:** Gabriel Anyaele

**Stack:** Prometheus, Grafana, AWS CloudWatch, CloudTrail, GuardDuty

**Repo:** `lab-dom08-monitoring/` (this repo) · app: [server_details](https://github.com/Ghaby-X/server_details), branch `feature/prometheus-metrics`

## 1. What was built

The `server_details` app from the CI/CD lab already ran as a container; it did not expose any metrics. This project added a zero-dependency `GET /metrics` endpoint (Prometheus text format: `http_requests_total` counter by method/route/status, `http_request_duration_seconds` histogram, process gauges) and a `GET /api/fail` diagnostic route for exercising error-rate alerting, then stood up a full stack around it:

- **Prometheus** on a dedicated EC2 host, scraping the app's `/metrics` and a **Node Exporter** sidecar on the app host for OS-level metrics (CPU, memory). Targets are discovered live via the EC2 API (tag + VPC filtered), not a static IP, so replacing the app instance never leaves Prometheus scraping a dead address.
- **Grafana**, provisioned with a Prometheus datasource and a dashboard covering requests/sec, p50/p95/p99 latency, error rate, and host CPU/memory.
- An **alerting rule** (`HighErrorRate`) evaluated by Prometheus itself: 5xx responses over 5% of traffic for 30 seconds, plus a second rule (`AppTargetDown`) for scrape failures.
- **CloudWatch Logs** via the Docker `awslogs` log driver on the app container - no sidecar agent, no polling; the container's stdout streams structured JSON access logs (method, path, status, duration, client IP) to `/lab-dom08/app` on every request.
- **CloudTrail**, multi-region, delivering to both an **encrypted** (SSE-S3/AES256), **lifecycled** (Standard-IA at 30 days → Glacier at 90 → expired at 365) S3 bucket, and to a CloudWatch Logs group for near-real-time querying.
- **GuardDuty**, a pre-existing regional detector (this account already had one) watching account activity for threats.

## 2. Why these choices

**Prometheus metrics were hand-rolled** The app is intentionally zero-runtime-dependency; The histogram buckets (5ms-10s) were sized for a Node.js app serving JSON from memory and static files from disk - sub-second by a wide margin.

**Two EC2 instances, not one.** Colocating Prometheus/Grafana with the thing they monitor hides a real failure mode: if the app host goes down, a colocated Prometheus goes down with it and can't alert on the outage. Splitting them means `AppTargetDown` is meaningful, and it forced solving live target discovery rather than a static IP - a real problem, caught and fixed mid-project (see §4).

**Alerting stayed in Prometheus, not Alertmanager.** The rule evaluation and firing state (Prometheus's own `/alerts`, and read-only in Grafana's Alerting view via the datasource).

**Error-rate threshold and window.** The brief asks for >5% - clearly above normal noise (occasional 404s from bots/scanners) but low enough that a real incident trips it fast. A 2-minute `rate()` window with a 30-second `for` was chosen for demo speed over production robustness - see §4 for what that traded away in practice.

**CloudTrail → both S3 and CloudWatch Logs.** S3 is the durable, cheap, lifecycled record required for audit/compliance; CloudWatch Logs is for the operational case - alerting on specific API calls or searching recent activity with Logs Insights without touching S3 at all.

**No open SSH CIDR.**

## 3. Verification; results

| Check | Result | Evidence |
| --- | --- | --- |
| Prometheus targets UP (app + node_exporter + prometheus itself) | **Pass** - 3/3 targets UP | `screenshots/prometheus targets.png` |
| Grafana dashboard live with real traffic | **Pass** - all 6 panels populated, 468 total requests captured over the session | `screenshots/grafana_dashboard.png` |
| `HighErrorRate` fires under induced load | **Pass** - **Firing**, value `0.811` (81.1% error rate) against the 5% threshold, active since `09:24:37Z` | `screenshots/prometheus_high_error_rate_alert.png` |
| App container logs visible in CloudWatch | **Pass** - structured JSON per request (method, path, status, durationMs, clientIp), confirmed live-tailing | `screenshots/cloudwatch_logs_server_details.png` |
| CloudTrail streaming to CloudWatch Logs | **Pass** - real management events (console `DescribeEvents`, `ListTelemetryPipelines`, etc.) captured with full request/identity context | `screenshots/cloudwatch_logs_cloudtrail.png` |
| S3 bucket encrypted + lifecycle rule present | **Pass (verified via CLI, not screenshotted)** - `aws s3api get-bucket-encryption` confirms AES256; `get-bucket-lifecycle-configuration` confirms Standard-IA/30d → Glacier/90d → expire/365d | not yet screenshotted - console → S3 → bucket → Properties tab |
| GuardDuty findings visible | **Pass, and organic rather than synthetic** - `Recon:EC2/PortProbeUnprotectedPort`, "An unprotected port on EC2 instance i-0eba6c2a54874df80 is being probed", port 3000, a real external host, first/last seen within an hour of the app going live | `screenshots/guardduty_unprotected_port_3000_findings.png` |

## 4. Insights

**The 81.1% observed error rate came from the `/api/fail` load test, not a real incident** - a curl loop hitting `/` and `/api/fail` unevenly, exactly as designed. Along the way it also showed the transition itself: an early screenshot caught the rule still Pending at `0.432` (43.2%), already past the 5% threshold but not yet through the 30-second `for` debounce; a longer sustained run past that window flipped it to Firing at `0.811`. Confirms detection is near-instant - the only delay is the deliberate debounce, not lag anywhere in the pipeline.

**Target discovery was the one real bug caught and fixed during the project, not before.** The original design baked the app host's private IP into Prometheus's config at boot time. The very first time the app instance was replaced (a routine `terraform apply -replace`, needed after a code push), Prometheus kept scraping the old, now-terminated instance's IP - `dial tcp ...: connect: no route to host` - with no error surfaced anywhere except a quiet gap in the dashboards. The fix (`ec2_sd_configs`, discovering the app host live via the EC2 API on every scrape cycle) removes the entire class of failure: there is no longer a stale value that can exist. This is the single most valuable thing this project produced beyond the checklist - a monitoring stack that doesn't quietly go blind the next time infrastructure underneath it changes.

**CloudTrail's scope is the whole account, not just this project's resources.** There's no way to scope a management-event trail to specific resources or tags - `is_multi_region_trail` and the lack of any event selector mean this trail captures every API call anyone makes in this AWS account, across every region. The evidence screenshot shows this directly: alongside this project's own activity, unrelated events from other work in the account (browsing CloudWatch Alarms, other applications' Lambda/DynamoDB activity) show up in the same log stream. Worth being explicit about in a security review - "CloudTrail is on" doesn't mean "this app is being watched," it means "everything is."

**GuardDuty needed no sample findings.** `app_allowed_cidr` defaults to `0.0.0.0/0` (the app dashboard is meant to be publicly reachable, matching the CI/CD lab's own pattern) - within roughly an hour of the app instance going live, GuardDuty had already flagged a real external host probing port 3000.

## 5. Cleanup

Not yet performed as of this report.
