"""GET /api/products, GET /api/products/<id> - read-only, straight
from Postgres.
"""
import logging

from flask import Blueprint, abort, jsonify
from psycopg2 import Error as PostgresError

from db import get_pool

logger = logging.getLogger(__name__)

bp = Blueprint('products', __name__, url_prefix='/api/products')


def _row_to_product(row):
    return {
        'id': row[0],
        'name': row[1],
        'priceCents': row[2],
        'stock': row[3],
        'imageUrl': row[4],
    }


@bp.get('')
def list_products():
    conn = get_pool().getconn()
    try:
        with conn.cursor() as cur:
            cur.execute('SELECT id, name, price_cents, stock, image_url FROM products ORDER BY id')
            rows = cur.fetchall()
        return jsonify([_row_to_product(r) for r in rows])
    except PostgresError:
        logger.error('failed to list products', exc_info=True)
        abort(500, description='internal error')
    finally:
        get_pool().putconn(conn)


@bp.get('/<int:product_id>')
def get_product(product_id):
    conn = get_pool().getconn()
    try:
        with conn.cursor() as cur:
            cur.execute(
                'SELECT id, name, price_cents, stock, image_url FROM products WHERE id = %s',
                (product_id,)
            )
            row = cur.fetchone()
        if row is None:
            logger.info('product not found', extra={'productId': product_id})
            abort(404, description='product not found')
        return jsonify(_row_to_product(row))
    except PostgresError:
        logger.error('failed to fetch product', exc_info=True, extra={'productId': product_id})
        abort(500, description='internal error')
    finally:
        get_pool().putconn(conn)
