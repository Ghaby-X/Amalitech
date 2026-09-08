"""Central place for every environment variable this service reads."""
import os

PORT = int(os.environ.get('PORT', 3000))

# Just the backend's hostname - "backend" in Compose, a Cloud Map DNS
# name on ECS, a K8s Service name on EKS. Scheme and port aren't part
# of this because they never change across environments (always plain
# http, always 8000 - it's our own image on our own fixed port
# everywhere), so there's exactly one thing to get right per
# environment when wiring this up.
BACKEND_SERVICE = os.environ.get('BACKEND_SERVICE', 'localhost')
BACKEND_PORT = 8000
BACKEND_URL = f'http://{BACKEND_SERVICE}:{BACKEND_PORT}'

# Signs the flash-message cookie only - no real session/auth data ever
# rides on it, so a fixed dev default is fine locally; set a real
# value via env in every other environment.
SECRET_KEY = os.environ.get('SECRET_KEY', 'dev-secret-change-me')
