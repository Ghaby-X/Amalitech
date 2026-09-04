# Project: Advanced Observability & Distributed Tracing — Report

**Author:** Gabriel Anyaele

**Stack:** OpenTelemetry, Prometheus, Grafana, Jaeger v2, AWS CloudWatch

**Repo:** `lab-dom09-advanced-monitoring/` (this repo) · app: [server_details](https://github.com/Ghaby-X/server_details), branch `feature/otel-tracing`

## 1. What was built

This project extends `server_details` (already instrumented for RED metrics/CloudWatch in [lab-dom08-monitoring](../lab-dom08-monitoring)) with OpenTelemetry-based distributed tracing, and wires that into the existing Prometheus/Grafana/CloudWatch stack:

- **OpenTelemetry instrumentation** — `tracing.js` bootstraps the Node SDK (`--require`-loaded, so HTTP auto-instrumentation patches `http` before the app code runs). Auto-instrumentation covers the HTTP server for free; one manual span (`collect-server-info`, on the shared `collectServerInfo()` function) demonstrates span nesting driven purely by call-site context - the same function's span lands under the request root when called from `/api/server-info`, or one level deeper under `/api/slow`'s work, with no span object ever passed explicitly. A new `/api/slow` route (~400ms artificial delay) gives the latency side of the brief something concrete to trigger.
- **Structured logs with trace correlation** - every access-log line carries `traceId`/`spanId` when a trace is active, plus a `level` (`info`/`warn`/`error`) derived from the response status code, so CloudWatch Logs Insights can filter by severity or jump straight from a log line to its matching trace.
- **A second app container** (`app-otel`, port 3001, built from `feature/otel-tracing`) runs alongside the original, untouched `app` container (port 3000) on lab-dom08's existing app host - both ship logs to the same CloudWatch log group, on separate streams.
- **Jaeger v2** (`jaegertracing/jaeger`, not the legacy `all-in-one` v1 image) runs as a standalone container on lab-dom08's existing monitoring host, receiving OTLP traces from `app-otel` and serving the trace UI/query API.
- **Prometheus** gets one additional scrape job (`server_details_app_otel`, targeting port 3001); RED metrics themselves are unchanged, reused directly from lab-dom08's hand-rolled `/metrics` collector.
- **Grafana** dashboard extended with RED panels, CPU/memory, and two "trace links" tables (`Traces (latency > 300ms)`, `Traces (Error - 500 responses)`) - each row's trace ID is a clickable data link straight into Jaeger.
- **Alerting** - two alerts, both confirmed firing and resolving via Slack under real `/api/fail` load: `HighErrorRate` reused unchanged from lab-dom08 (its query has no `job` filter, so it already covered the new instrumented instance's traffic without any changes), plus a new Grafana-managed alert, `Otel - High Error Rate`, scoped specifically to `app=otel`.

## 2. Why these choices

**Extended lab-dom08's live instances, touched nothing in its git-tracked config.** The brief explicitly asks to reuse the same app/EC2 runtime from previous projects. Every change needed on the live boxes - security group rules, the Jaeger container, the Prometheus scrape job, the second app container - was made by hand (SSH/console) rather than by editing `lab-dom08-monitoring/`'s terraform, keeping that project's own committed state untouched and independently gradable.

**A second container, not a replacement.** `app-otel` runs alongside the original `app` container rather than replacing it - zero risk to lab-dom08's already-working deployment, and it let this project be built and iterated on independently.

**Jaeger v2 over the legacy `all-in-one` image.** v1 was stood up first and proven working end-to-end, then deliberately swapped once a Docker Hub timestamp check showed `jaegertracing/all-in-one` (last updated 2025-12-03) is now maintenance-only versus `jaegertracing/jaeger` v2's active development (2026-07-20). The migration was scoped narrowly - same OTLP ports, same container name, same in-memory storage tradeoff as v1 - specifically so nothing downstream (Grafana's datasource, the app's export target) needed to change.

**`HighErrorRate` reused as-is, plus one new Grafana-managed alert scoped to the otel app.**.  `Otel - High Error Rate` was added on top of it existing application, specifically labeled `app=otel` so it's unambiguous which alert fired for which instance when both show up in the same Slack channel

**Trace-links panel via Table view + a manual data link, not the native Traces visualization.** The native panel type never rendered search results in this Grafana 11.2.0 / Jaeger combination, despite the underlying query genuinely returning data (confirmed via Table view and TraceID lookup both working).

## 3. Verification — results

| Check | Result | Evidence |
| --- | --- | --- |
| App exports traces to Jaeger | **Pass** - `server_details-app-otel` registered as a service, traces flowing (20 most-recent in one fetch) | `screenshots/jaeger.png` |
| Grafana dashboard: RED metrics + CPU/mem | **Pass** - RPS by route, error rate with 5% threshold line, p50/p95/p99 latency, CPU/memory gauges, 1800+ total requests, all populated with live traffic | `screenshots/grafana-dashboard.png` |
| Trace links panel | **Pass** - two Table-view panels (latency>300ms, error-500) with clickable trace-ID data links into Jaeger | `screenshots/grafana-dashboard.png` |
| Manual span nesting (`collect-server-info`) | **Pass** - confirmed via direct Jaeger API queries: nests under the root `GET` span when called from `/api/server-info`, one level deeper under `/api/slow`'s work when called from there | verified via API during development, not separately screenshotted |
| `traceId`/`spanId` in structured logs | **Pass** - every access-log line in CloudWatch carries both fields | `screenshots/cloudwatch-logs.png` |
| Alert → trace → log correlation | **Pass, and specifically verified, not just plausible** - a single trace ID confirmed identical across four independent views: the Slack alert notification, the dashboard's error-traces table, Grafana's trace detail (Explore → Jaeger, showing `error=true`/`status_code=500`), and a CloudWatch Logs query filtered to that exact `traceId`, returning the one matching `/api/fail` log line | `screenshots/correlation-evidence-01-alert-firing.png`, `screenshots/correlation-evidence-02-grafana-dashboard.png`, `screenshots/correlation-evidence-03-cloudwatch.png`, `screenshots/grafana-trace.png` |
| `HighErrorRate` and `Otel - High Error Rate` fire under induced load | **Pass** - both alerts fired and resolved on real `/api/fail` load, delivered via Slack through the Grafana webhook | `screenshots/correlation-evidence-01-alert-firing.png` |
| Prometheus targets: all scrape pools `UP` | **Pass** - `node_exporter`, `prometheus`, `server_details_app`, `server_details_app_otel`, each `1/1 up` | `screenshots/prometheus-target.png` |
| Tool version evidence | **Pass** - `jaegertracing/jaeger 2.20.0`, `grafana/grafana 11.2.0`, `prom/prometheus v2.54.1` (via `docker image ls`), OTel SDK dependency versions (`package.json`) | `screenshots/tools-versioning.png`, `screenshots/opentelemetry-versioni.png` |

## 4. Insights

**Two separate infrastructure gotchas cost more debugging time than the actual OpenTelemetry work.** First: Prometheus's config file is bind-mounted as a *single file* in `docker-compose.monitoring.yml`, and a single-file bind mount is bound to the file's inode at container start, not its path. Editors that save via write-temp-then-rename (the default for most of them) create a new inode at the same path - the host sees the new content instantly, but the already-running container keeps serving the old inode forever. `/-/reload` returning a clean `200 OK` with zero parse errors in the logs was a genuine false positive - the reload mechanism worked perfectly on a file the container could no longer see the current version of. `docker restart` was the actual fix, and it now applies to every future edit of that file, not just this one.

Second, and more subtle: AWS security groups still evaluate traffic from a container to its own instance's private IP, at least on Nitro-based instance types. A security group rule scoped to an admin's browser IP worked fine for humans, but silently blocked the exact same request when Grafana (running inside a container on the same box) tried to reach Jaeger via that box's own private IP - traffic that "never leaves the host" still gets treated as real network traffic by AWS's security group layer. The fix was a self-referencing security group rule, the standard pattern for "let resources behind this group talk to each other," which wouldn't have been the first thing to reach for without seeing the connection fail despite the file being correct, the port being open to *someone*, and `wget` from inside the container against the exact same URL succeeding only after that rule existed.

## 5. Cleanup

Not yet performed. This project's own additions - the `app-otel` and `jaeger` containers, the Prometheus scrape job, the two new security group rules - can be torn down independently of lab-dom08's underlying instances, which stay running by design (per the "extend existing infra" decision) and are not scheduled for teardown as part of this project.
