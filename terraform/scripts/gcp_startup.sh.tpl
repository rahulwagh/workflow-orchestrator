#!/bin/bash
set -euo pipefail

# ─── System Update & Dependencies ────────────────────────────────────────────
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y python3 python3-pip python3-venv

# ─── App Directory Setup ──────────────────────────────────────────────────────
mkdir -p /app/logs
chown -R ubuntu:ubuntu /app

# ─── Write Flask App ──────────────────────────────────────────────────────────
cat <<'APPEOF' > /app/app.py
${app_py}
APPEOF

chown ubuntu:ubuntu /app/app.py

# ─── Python Virtual Environment & Dependencies ───────────────────────────────
sudo -u ubuntu python3 -m venv /app/venv
sudo -u ubuntu /app/venv/bin/pip install --upgrade pip
sudo -u ubuntu /app/venv/bin/pip install flask==3.0.3

# ─── Systemd Service ──────────────────────────────────────────────────────────
cat <<'SERVICEEOF' > /etc/systemd/system/flask-app.service
[Unit]
Description=Flask Application
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/app
Environment="PATH=/app/venv/bin"
ExecStart=/app/venv/bin/python /app/app.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICEEOF

# ─── Enable & Start Service ───────────────────────────────────────────────────
systemctl daemon-reload
systemctl enable flask-app
systemctl start flask-app
