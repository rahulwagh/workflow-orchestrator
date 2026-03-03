import logging
import os
import random
import time
from datetime import datetime

from flask import Flask, jsonify, request

# ─── Logging Setup ────────────────────────────────────────────────────────────
os.makedirs("/app/logs", exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler("/app/logs/app.log"),
        logging.StreamHandler(),
    ],
)
logger = logging.getLogger(__name__)

# ─── Flask App ────────────────────────────────────────────────────────────────
app = Flask(__name__)


@app.route("/health")
def health():
    logger.info("Health check requested")
    return jsonify({"status": "healthy", "timestamp": datetime.utcnow().isoformat()})


@app.route("/api/data")
def get_data():
    # Simulate ~30% DB timeout errors for Kestra AI monitoring demo
    if random.random() < 0.3:
        logger.error("Database timeout: connection pool exhausted after 30s")
        return jsonify({"error": "Database timeout", "code": "DB_TIMEOUT"}), 500

    logger.info("Data request successful")
    return jsonify(
        {
            "status": "success",
            "data": {
                "id": random.randint(1, 1000),
                "value": round(random.uniform(10.0, 99.9), 2),
                "timestamp": datetime.utcnow().isoformat(),
            },
        }
    )


@app.route("/api/slow")
def slow_endpoint():
    # Occasionally simulate a slow response
    delay = random.uniform(0.1, 2.0)
    if delay > 1.5:
        logger.warning(f"Slow response detected: {delay:.2f}s latency")
    time.sleep(delay)
    return jsonify({"status": "success", "latency_ms": round(delay * 1000)})


@app.route("/logs")
def get_logs():
    # Returns last N lines of app.log — consumed by Kestra's http.Request task.
    # Avoids SSH entirely: Kestra just calls this endpoint over HTTP.
    log_file = "/app/logs/app.log"
    lines = int(request.args.get("lines", 50))
    try:
        with open(log_file, "r") as f:
            content = f.readlines()
        recent = "".join(content[-lines:])
        return jsonify({"lines": lines, "logs": recent})
    except FileNotFoundError:
        return jsonify({"lines": 0, "logs": ""}), 200


@app.route("/")
def index():
    logger.info("Root endpoint accessed")
    return jsonify(
        {
            "app": "Flask Multi-Cloud Demo",
            "version": "1.0.0",
            "endpoints": ["/health", "/api/data", "/api/slow", "/logs"],
        }
    )


if __name__ == "__main__":
    logger.info("Starting Flask app on 0.0.0.0:5000")
    app.run(host="0.0.0.0", port=5000)
