"""
GET/POST /api/cart, DELETE /api/cart/<product_id>.
"""
import logging
import uuid

from flask import Blueprint, abort, jsonify, make_response, request
from psycopg2 import Error as PostgresError
from redis import RedisError

import config
from cache import load_cart, save_cart
from db import get_pool

logger = logging.getLogger(__name__)

bp = Blueprint('cart', __name__, url_prefix='/api/cart')


def _enrich(items):
    """items: {product_id: qty} -> (line items with product details, total_cents)."""
    if not items:
        return [], 0

    conn = get_pool().getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                'SELECT id, name, price_cents FROM products WHERE id = ANY(%s)',
                (list(items.keys()),)
            )
            products = {row[0]: (row[1], row[2]) for row in cur.fetchall()}
    except PostgresError:
        logger.error('failed to enrich cart', exc_info=True)
        abort(500, description='internal error')
    finally:
        get_pool().putconn(conn)

    lines = []
    total_cents = 0
    for product_id, qty in items.items():
        if product_id not in products:
            continue
        name, price_cents = products[product_id]
        line_total = price_cents * qty
        total_cents += line_total
        lines.append({
            'productId': product_id,
            'name': name,
            'priceCents': price_cents,
            'qty': qty,
            'lineTotalCents': line_total,
        })
    return lines, total_cents


def _load_cart_or_500(cart_id):
    try:
        return load_cart(cart_id)
    except RedisError:
        logger.error('failed to load cart', exc_info=True, extra={'cartId': cart_id})
        abort(500, description='internal error')


def _save_cart_or_500(cart_id, items):
    try:
        save_cart(cart_id, items)
    except RedisError:
        logger.error('failed to save cart', exc_info=True, extra={'cartId': cart_id})
        abort(500, description='internal error')


@bp.get('')
def get_cart():
    cart_id = request.cookies.get(config.CART_COOKIE_NAME)
    lines, total_cents = _enrich(_load_cart_or_500(cart_id))
    return jsonify(items=lines, totalCents=total_cents)


@bp.post('')
def add_to_cart():
    body = request.get_json(silent=True) or {}
    product_id = body.get('productId')
    qty = body.get('qty')

    if not isinstance(product_id, int) or not isinstance(qty, int) or qty <= 0:
        abort(400, description='productId and a positive integer qty are required')

    cart_id = request.cookies.get(config.CART_COOKIE_NAME) or str(uuid.uuid4())

    items = _load_cart_or_500(cart_id)
    items[product_id] = items.get(product_id, 0) + qty
    _save_cart_or_500(cart_id, items)

    logger.info('item added to cart', extra={'cartId': cart_id, 'productId': product_id, 'qty': qty})

    lines, total_cents = _enrich(items)
    resp = make_response(jsonify(items=lines, totalCents=total_cents))
    resp.set_cookie(config.CART_COOKIE_NAME, cart_id, max_age=config.CART_TTL_SECONDS, httponly=True)
    return resp


@bp.delete('/<int:product_id>')
def remove_from_cart(product_id):
    cart_id = request.cookies.get(config.CART_COOKIE_NAME)
    items = _load_cart_or_500(cart_id)
    items.pop(product_id, None)

    if cart_id:
        _save_cart_or_500(cart_id, items)

    logger.info('item removed from cart', extra={'cartId': cart_id, 'productId': product_id})

    lines, total_cents = _enrich(items)
    return jsonify(items=lines, totalCents=total_cents)
