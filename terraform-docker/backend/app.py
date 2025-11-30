import os
import time
from datetime import datetime

from flask import Flask, request, jsonify

import psycopg2 
from psycopg2.extras import RealDictCursor

from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

# static information as metric
app = Flask(__name__)

note_count = Counter(
    "notes_created",
    "Total number of notes created",
)

total_requests = Counter(
    "http_requests_total",
    "Total number of HTTP requests",
    ["method", "endpoint", "http_status"],
)

latency = Histogram(
    "http_request_duration_seconds",
    "Histogram of HTTP request latency (seconds)",
    ["method", "endpoint"],
)

def get_db_connection():
    conn = psycopg2.connect(
        host=os.environ.get("DB_HOST", "postgres"),
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ.get("DB_NAME", "db"),
        user=os.environ.get("DB_USER", "postgres"),
        password=os.environ.get("DB_PASSWORD", "postgres"),
    )
    return conn


def wait_for_db(max_retries, delay):

    for attempt in range(1, max_retries + 1):
        try:
            conn = get_db_connection()
            conn.close()
            print(f"Database connection established on attempt {attempt}.")
            return

        except psycopg2.OperationalError as e:

            # Postgres may accept connections but not be ready, had issues where it would fail to connect after the container was made
            message = str(e)

            print(f"Database not ready (attempt {attempt}/{max_retries}): {message}")

            time.sleep(delay)

    raise RuntimeError("Could not connect to the database after multiple attempts.")


def init_db():

    wait_for_db(max_retries=10, delay=3)

    conn = get_db_connection()
    try:
        with conn.cursor() as cur:
            cur.execute(
                """
                CREATE TABLE IF NOT EXISTS notes (
                    id SERIAL PRIMARY KEY,
                    title TEXT NOT NULL,
                    content TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
                );
                """
            )
            conn.commit()
    finally:
        conn.close()

with app.app_context():
    init_db()

@app.route("/notes", methods=["GET"])
def get_notes():
    start = time.time()
    conn = get_db_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                "SELECT id, title, content, created_at FROM notes ORDER BY created_at DESC;"
            )
            rows = cur.fetchall()
            return jsonify(rows), 200
    finally:
        conn.close()

        # Record metrics
        dur = time.time() - start
        latency.labels(method="GET", endpoint="/notes").observe(dur)
        total_requests.labels(method="GET", endpoint="/notes", http_status=200).inc()

@app.route("/notes", methods=["POST"])
def create_note():
    data = request.get_json(silent=True) or {}

    title = data.get("title")
    content = data.get("content")

    if not title or not content:
        return jsonify({"error": "title and content are required"}), 400

    start = time.time()
    conn = get_db_connection()
    try:
        with conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor) as cur:
            cur.execute(
                """
                INSERT INTO notes (title, content)
                VALUES (%s, %s)
                RETURNING id, title, content, created_at;
                """,
                (title, content),
            )
            row = cur.fetchone()
            conn.commit()
            note_count.inc()
            return jsonify(row), 201
    finally:
        conn.close()

        # Record metrics
        dur = time.time() - start
        latency.labels(method="POST", endpoint="/notes").observe(dur)
        total_requests.labels(method="POST", endpoint="/notes", http_status=201).inc()

@app.route("/metrics", methods=["GET"])
def metrics():
    return generate_latest(), 200, {"Content-Type": CONTENT_TYPE_LATEST}

if __name__ == "__main__":
    # Let Docker expose the port
    app.run(host="0.0.0.0", port=3000, debug=False)