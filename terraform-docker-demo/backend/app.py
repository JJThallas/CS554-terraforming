import os
from datetime import datetime

from flask import Flask, request, jsonify
import psycopg2
import psycopg2.extras

app = Flask(__name__)


def get_db_connection():
    conn = psycopg2.connect(
        host=os.environ.get("DB_HOST", "postgres-demo"),
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ.get("DB_NAME", "demo_db"),
        user=os.environ.get("DB_USER", "postgres"),
        password=os.environ.get("DB_PASSWORD", "postgres"),
    )
    return conn

def init_db():
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

@app.route("/notes", methods=["POST"])
def create_note():
    data = request.get_json(silent=True) or {}

    title = data.get("title")
    content = data.get("content")

    if not title or not content:
        return jsonify({"error": "title and content are required"}), 400

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
            return jsonify(row), 201
    finally:
        conn.close()

if __name__ == "__main__":
    # Let Docker expose the port
    app.run(host="0.0.0.0", port=3000, debug=False)