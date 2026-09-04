# lab-dom09 Implementation Notes

Working log of what was decided and built for the advanced observability & distributed tracing project. See [README.md](README.md) for the project summary; this file is the detailed record.

## 1. Scope & approach

- **No new infrastructure.** This project extends the already-running `lab-dom08-monitoring` app host and monitoring host rather than provisioning a fresh stack - matches the brief's "reuse the same app and EC2 runtime from previous projects."
- **Nothing in `lab-dom08-monitoring/` (git) is touched.** Any change to the live boxes needed to support this project is made by hand (SSH), never by editing `lab-dom08-monitoring`'s terraform or committed config. Anything that needs to be a submission artifact is copied into this folder instead.
- **Jaeger runs on the monitoring host**, as a standalone container (not folded into the existing `docker-compose.yml`) - keeps it independent of lab-dom08's compose file.
- **The instrumented app runs as a second container, on a different port, on the same app host** - `app` (original, port 3000, untouched) and `app-otel` (new, port 3001, OTel-instrumented). This avoids replacing or risking the original app container.

## 2. App-side instrumentation

Repo: [`server_details`](https://github.com/Ghaby-X/server_details), branch `feature/otel-tracing` (off `feature/prometheus-metrics`).

### New dependencies

`@opentelemetry/api`, `@opentelemetry/sdk-node`, `@opentelemetry/auto-instrumentations-node`, `@opentelemetry/exporter-trace-otlp-http`, `@opentelemetry/resources`, `@opentelemetry/semantic-conventions`. First real dependencies this app has ever had - previously zero-dependency by design.

### New files

- **`tracing.js`** - OpenTelemetry SDK bootstrap. Loaded via `node --require ./tracing.js server.js` (not a plain `require()` inside `server.js`) so that HTTP auto-instrumentation patches Node's `http` module before `server.js` ever touches it. Configures:
  - `resource`: `service.name` (env `OTEL_SERVICE_NAME`, default `server_details-app`), `service.version`, `deployment.environment`
  - `traceExporter`: `OTLPTraceExporter` posting to `${OTEL_EXPORTER_OTLP_ENDPOINT}/v1/traces` (env, default `http://localhost:4318`)
  - `instrumentations`: `getNodeAutoInstrumentations()` - the full bundle; only `http` actually fires, since the app has no DB and makes no outbound HTTP calls
  - Graceful shutdown on `SIGTERM`/`SIGINT` - flushes any spans not yet exported before exit
- **`lib/tracer.js`** - exports a shared `tracer` (`trace.getTracer('server_details-app')`) for manual spans.

### Changed files

- **`lib/logger.js`** - reads the active span via `trace.getSpan(context.active())` and stamps `traceId`/`spanId` onto every structured JSON log line, when a trace is active. Degrades silently (no trace fields) when the SDK isn't running - this is what keeps `npm test` decoupled from tracing infra.
- **`server.js`**:
  - `collectServerInfo(req)` extracted as a standalone function (previously inlined in the `/api/server-info` handler), wrapped in one manual span: `tracer.startActiveSpan('collect-server-info', ...)`. Called from both `/api/server-info` (nests directly under the auto `GET` span) and `/api/slow` (nests the same way, purely because of where in the call graph it's invoked from - no span object passed explicitly, demonstrating OTel's implicit context propagation).
  - New route `GET /api/slow` - ~400ms artificial delay via `setTimeout`, then returns a JSON body that includes `collectServerInfo()`'s result. Exists specifically to exercise the latency alert and give traces an unambiguous root cause.
  - Deliberately reverted to **one** manual span total, on the shared function only - earlier iterations added spans to every route handler individually (`/metrics`, `/api/fail`, `/api/server-info`, plus two sibling spans inside `/api/slow`); all of that was stripped back out once it was clear the auto-instrumented root span already covers "a request happened," and extra manual spans on every route added little beyond what one well-placed span already demonstrates.
- **`lib/metrics.js`** - `normalizeRoute()` updated to recognize `/api/slow` (previously fell through to the generic `'static'` label, which would have silently merged the deliberate 400ms delay's metrics into unrelated static-asset-serving metrics).
- **`Dockerfile`** - now runs `npm ci --omit=dev` (previously no install step at all, since there were no dependencies); copies `tracing.js`; `CMD` changed to `["node", "--require", "./tracing.js", "server.js"]`.
- **`package.json`** - `"start"` script updated to `node --require ./tracing.js server.js`; `"test"` script deliberately left as plain `node --test` (no `--require`), so tests run fully decoupled from any OTLP endpoint being reachable.
- **`test/server.test.js`** - added a test for `/api/slow` (asserts ≥400ms elapsed, 200 status, JSON body shape).

### Verification performed (local only, before any AWS work)

Spun up a throwaway `jaegertracing/all-in-one` container locally, ran the app against it with `--require ./tracing.js`, and confirmed end-to-end:

- `traceId` in the JSON access log for a request matches a real trace in Jaeger's API
- `service_details-app` (later `server_details-app`) shows up as a registered service in Jaeger
- `/api/slow`'s trace shows `GET` (root, auto) → `collect-server-info` (manual child), with the child's duration accounting for the delay
- `/api/server-info`'s trace shows the same nesting shape, called from a different route
- All 13 tests (`npm test`) pass throughout every iteration of these changes

Nothing in this section has been deployed to AWS yet - it's app-repo work only, not yet merged/pushed.

## 3. Infrastructure plan (manual steps, not yet executed as of writing)

All values below are current as of this session: app host `10.1.1.246` (`sg-0225297579027e27c`), monitoring host `10.1.1.229` (`sg-03cf53adaf0a4ae7d`), VPC `vpc-0220afc4858ff63df`, region `eu-west-1`.

### Step 1 - Security group rules (AWS Console)

On `monitoring_sg` (`sg-03cf53adaf0a4ae7d`), add two inbound rules:

- Port `4318` (TCP), source = `sg-0225297579027e27c` (app_sg) - lets the app host push traces
- Port `16686` (TCP), source = admin IP/CIDR - so the Jaeger UI is reachable in a browser

### Step 2 - Jaeger on the monitoring host

**Runs Jaeger v2** (`jaegertracing/jaeger`)

The config also lives at [`jaeger/config.yaml`](jaeger/config.yaml) in this repo, as the submission deliverable for "Jaeger config."

SSH in (`terraform output ssh_monitoring`), then:

```bash
mkdir -p /opt/monitoring/jaeger
cat <<'EOF' > /opt/monitoring/jaeger/config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:

extensions:
  jaeger_storage:
    backends:
      memstore:
        memory:
          max_traces: 100000
  jaeger_query:
    storage:
      traces: memstore
    http:
      endpoint: 0.0.0.0:16686

exporters:
  jaeger_storage_exporter:
    trace_storage: memstore

service:
  extensions: [jaeger_storage, jaeger_query]
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [jaeger_storage_exporter]
EOF

# run jaeger application
docker run -d \
  --name jaeger \
  --restart unless-stopped \
  -p 16686:16686 \
  -p 4317:4317 \
  -p 4318:4318 \
  -v /opt/monitoring/jaeger/config.yaml:/etc/jaeger/config.yaml:ro \
  jaegertracing/jaeger:latest \
  --config /etc/jaeger/config.yaml
```

### Step 3 - Add the Prometheus scrape job (same host)

Edit `/opt/monitoring/prometheus/prometheus.yml`, add under `scrape_configs:`:

```yaml
  - job_name: "server_details_app_otel"
    metrics_path: /metrics
    ec2_sd_configs:
      - region: eu-west-1
        port: 3001
        filters:
          - name: tag:Name
            values: ["lab-dom08-app"]
          - name: vpc-id
            values: ["vpc-0220afc4858ff63df"]
          - name: instance-state-name
            values: ["running"]
    relabel_configs:
      - target_label: instance_role
        replacement: app
```

```bash
docker restart prometheus
```

### Step 4 - Add the Error alert rule (Grafana, not Prometheus)

- **Name:** `High Error Rate
- **Query (A):** datasource = Prometheus, query type = Instant, expression:

  ```promql
  100 * (sum(rate(http_requests_total{job="server_details_app_otel",status_code=~"5.."}[2m])) / sum(rate(http_requests_total{job="server_details_app_otel"}[2m])))
  )
  ```

- **Expression (B):** Threshold, input = A, condition = **IS ABOVE** `5`
- **Labels/annotations:** `severity=warning`; summary along the lines of "High p95 latency on server_details_app_otel"

### Step 5 - Second app container, on the app host

SSH in (`terraform output ssh_app`):

```bash
# clone new repo
git clone --branch feature/otel-tracing https://github.com/Ghaby-X/server_details.git /opt/app-otel
cd /opt/app-otel
docker build -t server-details:otel .

# get instance id
IMDS_TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" http://169.254.169.254/latest/meta-data/instance-id)

docker run -d \
  --name app-otel \
  --restart unless-stopped \
  -p 3001:3000 \
  -e OTEL_EXPORTER_OTLP_ENDPOINT=http://10.1.1.229:4318 \
  -e OTEL_SERVICE_NAME=server_details-app-otel \
  --log-driver awslogs \
  --log-opt awslogs-region=eu-west-1 \
  --log-opt awslogs-group=/lab-dom08/app \
  --log-opt awslogs-create-group=true \
  --log-opt awslogs-stream="app-otel/$INSTANCE_ID" \
  server-details:otel
```

Check: `docker ps` shows both `app` and `app-otel` running; `curl http://localhost:3001/api/server-info` returns JSON; `docker logs app-otel` shows the same JSON access-log lines seen locally (with `traceId`/`spanId`); within a minute, `aws logs tail /lab-dom08/app --follow` (or the console, filtering by log stream `app-otel/<instance-id>`) shows them arriving in CloudWatch too.

## 4. Verification plan (not yet run against real infra)

1. **Traces:** hit `/api/slow` and `/api/fail` a few times on port 3001, then check Jaeger's UI (`server_details-app-otel` in the service dropdown) for the traces - should show `GET → collect-server-info`.
2. **Metrics:** confirm `server_details_app_otel` target stays `UP` in Prometheus and its `http_requests_total`/`http_request_duration_seconds` series populate (Prometheus → Graph → query them) as a series distinct from the original `server_details_app` job - differentiated automatically by Prometheus's `job` label, nothing extra needed for that separation.
3. **Error alert (reused):** loop `/api/fail` similarly, confirm the existing `HighErrorRate` rule still fires, scoped to this job or the original - either is fine as evidence.
4. **Log correlation:**
check aws cloudwatch console
5. **Screenshots to capture along the way:** Jaeger trace waterfall, Prometheus targets page (all three job groups UP), `HighLatency` Firing, and the CloudWatch log line next to its matching Jaeger trace - that last pair is the "correlation evidence" deliverable specifically.
