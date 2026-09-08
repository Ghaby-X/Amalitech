"""ShopNow frontend - server-rendered pages, one call to the backend
per route. The browser never talks to the backend directly - every
route here does the fetch-then-render (or fetch-then-redirect) dance
of a traditional server-rendered app.
"""
import logging
import time

import requests
from flask import Flask, flash, g, make_response, redirect, render_template, request, url_for
from werkzeug.exceptions import HTTPException

import config
from logging_config import configure_logging

configure_logging()
logger = logging.getLogger(__name__)

app = Flask(__name__, static_url_path='')
app.secret_key = config.SECRET_KEY


@app.template_filter('money')
def money_filter(cents):
    return f'{cents / 100:.2f}'


def _backend(method, path, **kwargs):
    """One call to the backend, cookie forwarded both ways. Returns the
    requests.Response, or None if the backend couldn't be reached at
    all (logged here, with the call that failed). Callers degrade
    gracefully instead of crashing - matters once we start killing
    backend containers/pods to test recovery."""
    headers = kwargs.pop('headers', {})
    headers['cookie'] = request.headers.get('cookie', '')
    try:
        return requests.request(method, f'{config.BACKEND_URL}{path}', headers=headers, timeout=5, **kwargs)
    except requests.RequestException:
        logger.error('backend request failed', exc_info=True, extra={'method': method, 'path': path})
        return None


def _forward_cookie(resp, upstream):
    if upstream is not None and 'set-cookie' in upstream.headers:
        resp.headers['set-cookie'] = upstream.headers['set-cookie']
    return resp


def _redirect_with_upstream(upstream, fallback_error, redirect_endpoint, success_message=None):
    """Build the redirect response for a POST action, flashing either
    the backend's error, a generic 'unavailable' message, or a success
    message - then forwarding Set-Cookie when there's an actual
    response to forward. redirect_endpoint sends the user back to
    wherever the action was triggered from."""
    resp = make_response(redirect(url_for(redirect_endpoint)))

    if upstream is None:
        flash('Backend is temporarily unavailable - please try again shortly.', 'error')
        return resp

    if not upstream.ok:
        try:
            message = upstream.json().get('error', fallback_error)
        except ValueError:
            message = fallback_error
        flash(message, 'error')
    elif success_message:
        flash(success_message, 'success')

    return _forward_cookie(resp, upstream)


@app.before_request
def _start_timer():
    g.start_time = time.monotonic()


@app.after_request
def _log_request(response):
    duration_ms = round((time.monotonic() - g.start_time) * 1000, 2)
    logger.info(
        'request handled',
        extra={
            'method': request.method,
            'path': request.path,
            'status': response.status_code,
            'durationMs': duration_ms,
        }
    )
    return response


@app.get('/health')
def health():
    return {'status': 'ok', 'service': 'frontend'}


def _cart_summary():
    """Small header badge (item count + total) shown on every page -
    a light GET, not the itemized breakdown that /cart shows."""
    cart_resp = _backend('GET', '/api/cart')
    cart = cart_resp.json() if cart_resp is not None and cart_resp.ok else {'items': [], 'totalCents': 0}
    return cart, cart_resp


@app.get('/')
def index():
    products_resp = _backend('GET', '/api/products')
    cart, cart_resp = _cart_summary()

    if products_resp is None or cart_resp is None:
        flash('Backend is temporarily unavailable - please try again shortly.', 'error')

    products = products_resp.json() if products_resp is not None and products_resp.ok else []

    resp = make_response(render_template('index.html', products=products, cart=cart))
    return _forward_cookie(resp, cart_resp)


@app.get('/cart')
def view_cart():
    cart, cart_resp = _cart_summary()

    if cart_resp is None:
        flash('Backend is temporarily unavailable - please try again shortly.', 'error')

    resp = make_response(render_template('cart.html', cart=cart))
    return _forward_cookie(resp, cart_resp)


@app.post('/cart')
def add_to_cart():
    product_id = request.form.get('productId', type=int)
    qty = request.form.get('qty', type=int)
    upstream = _backend('POST', '/api/cart', json={'productId': product_id, 'qty': qty})
    return _redirect_with_upstream(upstream, 'could not add item to cart', 'index')


@app.post('/cart/<int:product_id>/remove')
def remove_from_cart(product_id):
    upstream = _backend('DELETE', f'/api/cart/{product_id}')
    return _redirect_with_upstream(upstream, 'could not remove item', 'view_cart')


@app.post('/checkout')
def checkout():
    upstream = _backend('POST', '/api/checkout')
    success_message = None
    if upstream is not None and upstream.ok:
        order = upstream.json()
        success_message = f'Order #{order["id"]} confirmed - total ${order["totalCents"] / 100:.2f}'
    return _redirect_with_upstream(upstream, 'checkout failed', 'view_cart', success_message)


@app.errorhandler(HTTPException)
def handle_http_exception(e):
    # Real 404s/405s/etc. - pass through unchanged. Without this,
    # the generic Exception handler below would catch these too
    # (HTTPException is itself an Exception) and flatten every one of
    # them into a hardcoded 500.
    return e


@app.errorhandler(Exception)
def handle_unexpected_exception(e):
    logger.error('unhandled exception', exc_info=True)
    return 'Something went wrong.', 500


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=config.PORT)
