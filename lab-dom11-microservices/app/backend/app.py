"""ShopNow backend - Flask app entrypoint."""
import logging
import time

from flask import Flask, g, jsonify, request
from werkzeug.exceptions import HTTPException

import config
from db import ensure_schema
from logging_config import configure_logging
from routes.cart import bp as cart_bp
from routes.checkout import bp as checkout_bp
from routes.health import bp as health_bp
from routes.products import bp as products_bp

configure_logging()
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.register_blueprint(health_bp)
app.register_blueprint(products_bp)
app.register_blueprint(cart_bp)
app.register_blueprint(checkout_bp)


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


@app.errorhandler(HTTPException)
def handle_http_exception(e):
    return jsonify(error=e.description), e.code


@app.errorhandler(Exception)
def handle_unexpected_exception(e):
    logger.error('unhandled exception', exc_info=True)
    return jsonify(error='internal error'), 500


ensure_schema()


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=config.PORT)
