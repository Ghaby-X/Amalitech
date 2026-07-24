# Server Details & Visitor Counter Container Application

A dynamic Node.js server application that reports real-time server host system metrics and tracks global server-side visitor counts using an ACID-compliant SQLite database.

## Features
- **Real Server System Information**: Hostname, OS platform, CPU model & core count, CPU load average (1/5/15m), RAM utilization, system uptime.
- **SQLite Server-Side Visitor Counter**: Counts total visits and unique client IPs, persisting data in SQLite (`database.sqlite`).
- **Configurable Environment Variables**: `PORT`, `DATA_DIR`, `DB_NAME`, `NODE_ENV`, `REFRESH_INTERVAL_MS`.
- **REST APIs**:
  - `GET /api/server-info`: Returns live host telemetry.
  - `GET /api/visitor-count`: Logs visit and retrieves SQLite visitor analytics.

---

## Running with Docker Compose (Recommended)

Start the service using Docker Compose:

```bash
# Start container in background
docker compose up -d

# View logs
docker compose logs -f

# Stop container
docker compose down
```

---

## Building and Running with Docker CLI

### 1. Build the Docker Image
```bash
docker build -t server-details-site:latest .
```

### 2. Run Container with Volume & Custom Port
```bash
docker run -d \
  -p 8080:8080 \
  -e PORT=8080 \
  -e DATA_DIR=/app/data \
  -e DB_NAME=analytics.db \
  -v ./data:/app/data \
  --name server-details-app \
  server-details-site:latest
```

Access the app in your browser at `http://localhost:8080`.

---

## Tagging and Pushing to Docker Registry

### Push to Docker Hub
```bash
# 1. Tag image
docker tag server-details-site:latest YOUR_DOCKERHUB_USERNAME/server-details-site:latest

# 2. Push image
docker push YOUR_DOCKERHUB_USERNAME/server-details-site:latest
```

---

## Directory Structure
```
helpers/server_details_site/
├── Dockerfile
├── compose.yaml
├── .env.example
├── .dockerignore
├── package.json
├── server.js
├── public/
│   ├── index.html
│   ├── css/style.css
│   └── js/script.js
└── data/
    └── database.sqlite (persisted SQLite DB)
```
