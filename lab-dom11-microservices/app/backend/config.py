"""
Central place for every environment variable this service reads.
"""
import os

# Port for flask application
PORT = int(os.environ.get('PORT', 8000))

# Database and server url
PG_DATABASE_URL = os.environ.get('PG_DATABASE_URL', '')
REDIS_URL = os.environ.get('REDIS_URL', '')

CART_COOKIE_NAME = os.environ.get('CART_COOKIE_NAME', 'cart_id')
CART_TTL_SECONDS = int(os.environ.get('CART_TTL_SECONDS', 86400)) # last for 24 hours
