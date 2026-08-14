# nginx-proxy

A containerized Nginx reverse proxy that routes traffic to the Flask app from [`../docker-lab`](../docker-lab).

## Structure

```
nginx-proxy/
├── nginx.conf     Reverse proxy config - see below
├── Dockerfile     nginx:alpine, COPYs in nginx.conf
└── screenshots/
    ├── 001_flask_app_5000.png    http://localhost:5000 - the backend, direct
    ├── 002_nginx_app_8080.png    http://localhost:8080 - proxied through nginx
    └── 003_nginx_app_health.png  http://localhost:8080/nginx-health - nginx's own route
```

## How routing works

`nginx.conf` has two `location` blocks:

- `/nginx-health` - answered directly by nginx (`return 200`), never touches the backend. `access_log off` keeps routine health-check traffic out of the logs.
- `/` - proxied to the Flask app via `proxy_pass http://host.docker.internal:5000`.

## Usage

The backend must be running first - nginx proxies to it immediately on the first request.

```bash
# Backend (from docker-lab/)
docker build -t flask-app ../docker-lab
docker run -d -p 5000:5000 --name flask-app flask-app

# Proxy
docker build -t nginx-proxy .
docker run -d -p 8080:80 --add-host=host.docker.internal:host-gateway --name nginx-proxy nginx-proxy

curl http://localhost:8080/               # -> Hello from Docker! (proxied)
curl http://localhost:8080/nginx-health   # -> nginx-proxy OK (nginx itself)
```

**`--add-host=host.docker.internal:host-gateway` is required on native Linux Docker Engine.** Docker Desktop (Mac/Windows) resolves `host.docker.internal` automatically; Linux doesn't unless told to. Without this flag, nginx fails at startup with `host not found in upstream "host.docker.internal"` - it resolves upstream hostnames when it starts, so a missing entry is a hard failure, not just a bad request later.

## Cleanup

```bash
docker rm -f flask-app nginx-proxy
```

## Alternative: a custom Docker network instead of `host.docker.internal`

`host.docker.internal` is only needed because this setup runs two independent containers with no shared network - nginx has to go out to the host and back in via the published port. A user-defined network sidesteps that entirely, using Docker's built-in container-name DNS instead (the same mechanism `multi-container-app`'s Compose file uses for `web`/`db`):

```bash
docker network create app-net
docker run -d --network app-net --name flask-app flask-app
docker run -d --network app-net -p 8080:80 --name nginx-proxy nginx-proxy
```

With `nginx.conf`'s `proxy_pass` changed to `http://flask-app:5000` instead of `http://host.docker.internal:5000`. Not used here since the guide this lab follows specifies `host.docker.internal`, but worth knowing as the more typical pattern once multiple containers are meant to talk to each other.

## Tools

```
Docker version 29.5.2, build 79eb04c
Docker Compose version v5.1.4
```
