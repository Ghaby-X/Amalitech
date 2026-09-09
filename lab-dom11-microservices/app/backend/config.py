"""
Central place for every environment variable this service reads.
"""
import os

# Port for flask application
PORT = int(os.environ.get('PORT', 8000))

PGHOST = os.environ.get('PGHOST', 'localhost')
PGPORT = os.environ.get('PGPORT', '5432')
PGUSER = os.environ.get('PGUSER', 'shopnow')
PGPASSWORD = os.environ.get('PGPASSWORD', 'shopnow')
PGDATABASE = os.environ.get('PGDATABASE', 'shopnow')
PG_DATABASE_URL = f'postgresql://{PGUSER}:{PGPASSWORD}@{PGHOST}:{PGPORT}/{PGDATABASE}'

REDIS_HOST = os.environ.get('REDIS_HOST', 'localhost')
REDIS_PORT = os.environ.get('REDIS_PORT', '6379')
REDIS_PASSWORD = os.environ.get('REDIS_PASSWORD', '')
REDIS_URL = (
    f'redis://:{REDIS_PASSWORD}@{REDIS_HOST}:{REDIS_PORT}'
    if REDIS_PASSWORD else f'redis://{REDIS_HOST}:{REDIS_PORT}'
)

CART_COOKIE_NAME = os.environ.get('CART_COOKIE_NAME', 'cart_id')
CART_TTL_SECONDS = int(os.environ.get('CART_TTL_SECONDS', 86400)) # last for 24 hours
