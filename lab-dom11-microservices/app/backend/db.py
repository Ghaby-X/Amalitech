"""Postgres connection pool, schema bootstrap, and seed data.

No migration framework - the schema is two tables that don't change
shape mid-exercise, so idempotent DDL run at startup is enough.
CREATE TABLE IF NOT EXISTS and INSERT ... ON CONFLICT DO NOTHING are
both safe to run from every backend replica, every time it boots,
even if several of them race to do it at the same instant.
"""
import logging
import time

from psycopg2 import OperationalError, pool

import config

logger = logging.getLogger(__name__)

_pool = None

# Arbitrary fixed key for the schema-bootstrap advisory lock - just
# needs to be constant and not collide with anything else using
# advisory locks on this database (nothing else does).
SCHEMA_LOCK_KEY = 727001

SEED_PRODUCTS = [
    # name, price_cents, stock, image_url
    ('Wireless Mouse', 1499, 50, '/images/wireless-mouse.png'),
    ('Desk Lamp', 2499, 20, '/images/desk-lamp.jpg'),
    ('Backpack', 3999, 0, '/images/backpack.jpg'),
    ('Water Bottle', 1299, 35, '/images/water-bottle.jpg'),
    ('Bluetooth Speaker', 4999, 10, '/images/bluetooth-speaker.jpg'),
    ('Notebook', 499, 60, '/images/notebook.jpg'),
    ('Coffee Mug', 999, 15, '/images/coffee-mug.jpg'),
    ('Phone Stand', 799, 100, '/images/phone-stand.jpg'),
]


def _connect_with_retry(max_attempts=30, delay_seconds=1):
    """Postgres isn't guaranteed to be ready when this container starts,
    on Compose, ECS, or EKS alike - retry instead of crash-looping on
    the first attempt."""
    attempt = 0
    while True:
        attempt += 1
        try:
            return pool.SimpleConnectionPool(1, 10, dsn=config.PG_DATABASE_URL)
        except OperationalError as err:
            if attempt >= max_attempts:
                logger.error(
                    'giving up connecting to postgres after %d attempts: %s',
                    max_attempts, err, exc_info=True
                )
                raise
            logger.warning('postgres not ready (attempt %d/%d): %s', attempt, max_attempts, err)
            time.sleep(delay_seconds)


def get_pool():
    global _pool
    if _pool is None:
        _pool = _connect_with_retry()
    return _pool


def ensure_schema():
    """Create tables if missing and seed products.

    Wrapped in a Postgres advisory lock - CREATE TABLE IF NOT EXISTS
    alone isn't actually safe under true concurrency, since the
    existence check and the creation aren't atomic relative to
    another in-flight, uncommitted transaction doing the same thing.
    Without the lock, two processes bootstrapping a fresh database at
    the same instant (gunicorn's worker processes here, or separate
    ECS/EKS replicas in general) can both pass the check and then
    collide on creation. The lock makes whoever gets there first do
    the real work while everyone else blocks, then finds the table
    already committed by the time their turn comes.
    """
    conn = get_pool().getconn()
    try:
        with conn, conn.cursor() as cur:
            cur.execute('SELECT pg_advisory_lock(%s)', (SCHEMA_LOCK_KEY,))

        try:
            with conn, conn.cursor() as cur:
                cur.execute('''
                    CREATE TABLE IF NOT EXISTS products (
                        id SERIAL PRIMARY KEY,
                        name TEXT NOT NULL UNIQUE,
                        price_cents INTEGER NOT NULL,
                        stock INTEGER NOT NULL DEFAULT 0,
                        image_url TEXT NOT NULL DEFAULT ''
                    )
                ''')
                cur.execute('''
                    CREATE TABLE IF NOT EXISTS orders (
                        id SERIAL PRIMARY KEY,
                        cart_id TEXT NOT NULL,
                        items JSONB NOT NULL,
                        total_cents INTEGER NOT NULL,
                        created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                    )
                ''')
                for name, price_cents, stock, image_url in SEED_PRODUCTS:
                    cur.execute(
                        '''INSERT INTO products (name, price_cents, stock, image_url)
                           VALUES (%s, %s, %s, %s)
                           ON CONFLICT (name) DO NOTHING''',
                        (name, price_cents, stock, image_url),
                    )
            logger.info('schema ready, products seeded')
        finally:
            with conn, conn.cursor() as cur:
                cur.execute('SELECT pg_advisory_unlock(%s)', (SCHEMA_LOCK_KEY,))
    finally:
        get_pool().putconn(conn)
