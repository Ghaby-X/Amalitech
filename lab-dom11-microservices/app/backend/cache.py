"""Redis client, plus cart storage helpers.

A cart is just a JSON blob ({product_id: qty}) keyed by cart_id, with
a TTL so abandoned carts expire on their own instead of accumulating
forever.
"""
import json

import redis

import config

_client = None


def get_redis():
    global _client
    if _client is None:
        _client = redis.Redis.from_url(config.REDIS_URL, decode_responses=True)
    return _client


def cart_key(cart_id):
    return f'cart:{cart_id}'


def load_cart(cart_id):
    """Returns {product_id: qty} - empty dict if there's no cart_id, or
    nothing stored for it yet (e.g. it expired)."""
    if not cart_id:
        return {}
    raw = get_redis().get(cart_key(cart_id))
    if not raw:
        return {}
    return {int(k): v for k, v in json.loads(raw).items()}


def save_cart(cart_id, items):
    get_redis().setex(cart_key(cart_id), config.CART_TTL_SECONDS, json.dumps(items))


def clear_cart(cart_id):
    get_redis().delete(cart_key(cart_id))
