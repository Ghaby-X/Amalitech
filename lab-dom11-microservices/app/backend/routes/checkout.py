"""POST /api/checkout - purchases everything in the caller's cart.

Validates stock, decrements it, and records the order in one Postgres
transaction (via a row lock on the products being bought, so two
concurrent checkouts on the same product can't both succeed past the
stock they're actually entitled to), then clears the cart in Redis.
"""
import json
import logging

from flask import Blueprint, abort, jsonify, request
from psycopg2 import Error as PostgresError
from redis import RedisError

import config
from cache import clear_cart, load_cart
from db import get_pool

logger = logging.getLogger(__name__)

bp = Blueprint('checkout', __name__, url_prefix='/api/checkout')


@bp.post('')
def checkout():
    cart_id = request.cookies.get(config.CART_COOKIE_NAME)

    try:
        items = load_cart(cart_id)
    except RedisError:
        logger.error('failed to load cart for checkout', exc_info=True, extra={'cartId': cart_id})
        abort(500, description='internal error')

    if not items:
        abort(400, description='cart is empty')

    conn = get_pool().getconn()
    try:
        with conn, conn.cursor() as cur:
            cur.execute(
                'SELECT id, name, price_cents, stock FROM products WHERE id = ANY(%s) FOR UPDATE',
                (list(items.keys()),)
            )
            products = {
                row[0]: {'name': row[1], 'priceCents': row[2], 'stock': row[3]}
                for row in cur.fetchall()
            }

            for product_id, qty in items.items():
                product = products.get(product_id)
                if product is None or product['stock'] < qty:
                    logger.warning(
                        'checkout blocked - insufficient stock',
                        extra={'cartId': cart_id, 'productId': product_id, 'requestedQty': qty}
                    )
                    abort(409, description=f'insufficient stock for product {product_id}')

            order_items = []
            total_cents = 0
            for product_id, qty in items.items():
                product = products[product_id]
                cur.execute('UPDATE products SET stock = stock - %s WHERE id = %s', (qty, product_id))
                line_total = product['priceCents'] * qty
                total_cents += line_total
                order_items.append({
                    'productId': product_id,
                    'name': product['name'],
                    'qty': qty,
                    'priceCents': product['priceCents'],
                })

            cur.execute(
                '''INSERT INTO orders (cart_id, items, total_cents)
                   VALUES (%s, %s, %s)
                   RETURNING id, created_at''',
                (cart_id, json.dumps(order_items), total_cents)
            )
            order_id, created_at = cur.fetchone()
    except PostgresError:
        logger.error('checkout failed', exc_info=True, extra={'cartId': cart_id})
        abort(500, description='internal error')
    finally:
        get_pool().putconn(conn)

    try:
        clear_cart(cart_id)
    except RedisError:
        # Order already committed - a stale cart left behind is a much
        # smaller problem than losing the purchase, so log and move on
        # rather than failing the whole checkout at the last step.
        logger.error(
            'failed to clear cart after checkout', exc_info=True,
            extra={'cartId': cart_id, 'orderId': order_id}
        )

    logger.info(
        'order confirmed',
        extra={'cartId': cart_id, 'orderId': order_id, 'totalCents': total_cents}
    )

    return jsonify(
        id=order_id,
        items=order_items,
        totalCents=total_cents,
        createdAt=created_at.isoformat(),
    ), 201
