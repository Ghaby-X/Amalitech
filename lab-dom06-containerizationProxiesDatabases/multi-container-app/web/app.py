import json
import os
import time
from datetime import datetime, timezone

import boto3
import pymysql
from flask import Flask, jsonify

app = Flask(__name__)


DB_CONFIG = {
    "host": os.environ.get("MYSQL_HOST", "db"),
    "port": int(os.environ.get("MYSQL_PORT", 3306)),
    "user": os.environ.get("MYSQL_USER", "appuser"),
    "database": os.environ.get("MYSQL_DATABASE", "appdb"),
}

PASSWORD_CACHE_TTL = int(os.environ.get("PASSWORD_CACHE_TTL", 300))
_password_cache = {"value": None, "fetched_at": 0.0}


def _fetch_password_from_secrets_manager():
    secret_name = os.environ["AWS_SECRET_NAME"]
    region = os.environ.get("AWS_REGION", "eu-west-1")
    client = boto3.client("secretsmanager", region_name=region)
    secret = json.loads(client.get_secret_value(SecretId=secret_name)["SecretString"])
    return secret["MYSQL_PASSWORD"]


def get_db_password():
    if "AWS_SECRET_NAME" not in os.environ:
        return os.environ.get("MYSQL_PASSWORD", "apppassword")

    now = time.time()
    stale = (now - _password_cache["fetched_at"]) > PASSWORD_CACHE_TTL
    if _password_cache["value"] is None or stale:
        _password_cache["value"] = _fetch_password_from_secrets_manager()
        _password_cache["fetched_at"] = now
    return _password_cache["value"]


def get_connection(retries=10, delay=3):
    last_error = None
    for _ in range(retries):
        try:
            return pymysql.connect(
                connect_timeout=5, password=get_db_password(), **DB_CONFIG
            )
        except pymysql.err.OperationalError as exc:
            last_error = exc
            time.sleep(delay)
    raise last_error


PAGE = """<!doctype html>
<html>
<head><title>Visitor Counter</title></head>
<body style="font-family: sans-serif; text-align: center; margin-top: 4rem;">
    <h1>Visitor Counter</h1>
    <p style="font-size: 3rem; margin: 1rem 0;">{count}</p>
    <p>visits recorded in MySQL (host: <code>{host}</code>)</p>
    <p style="color: #666;">Last visit: {visited_at}</p>
</body>
</html>
"""


@app.route("/")
def home():
    now = datetime.now(timezone.utc)
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("INSERT INTO visits (visited_at) VALUES (%s)", (now,))
            conn.commit()
            cursor.execute("SELECT COUNT(*) FROM visits")
            count = cursor.fetchone()[0]
    finally:
        conn.close()
    return PAGE.format(count=count, host=DB_CONFIG["host"], visited_at=now.isoformat())


@app.route("/health")
def health():
    try:
        get_connection(retries=1, delay=0).close()
        return jsonify(status="ok", db="reachable"), 200
    except Exception as exc:
        return jsonify(status="error", db=str(exc)), 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
