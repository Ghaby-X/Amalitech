# docker-lab

Packages a simple Flask app into a Docker image and runs it locally.

## Structure

```
docker-lab/
├── app.py              Flask app - single route, returns "Hello from Docker!"
├── Dockerfile           python:3.9-slim, installs flask, EXPOSE 5000
├── .dockerignore
├── RUN_EVIDENCE.txt     Captured output of the commands below
└── screenshots/
    └── flask_app_5000.png   Browser screenshot of http://localhost:5000
```

## Usage

```bash
docker build -t flask-app .
docker run -d -p 5000:5000 --name flask-app flask-app
curl http://localhost:5000
```

Expected response: `Hello from Docker!`

## Cleanup

```bash
docker rm -f flask-app
```

## Tools

```
Docker version 29.5.2, build 79eb04c
Docker Compose version v5.1.4
```
