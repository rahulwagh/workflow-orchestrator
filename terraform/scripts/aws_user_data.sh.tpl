#!/bin/bash
set -euo pipefail

# ─── System Update & Dependencies ────────────────────────────────────────────
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y python3 python3-pip python3-venv curl

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

# ─── CloudWatch Agent ─────────────────────────────────────────────────────────
curl -fsSL \
  "https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb" \
  -o /tmp/amazon-cloudwatch-agent.deb

# dpkg exits non-zero on unmet deps; apt-get -f resolves them
dpkg -i /tmp/amazon-cloudwatch-agent.deb || apt-get install -f -y

mkdir -p /opt/aws/amazon-cloudwatch-agent/etc

cat <<'CWEOF' > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/app/logs/app.log",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC",
            "timestamp_format": "%Y-%m-%d %H:%M:%S,%f",
            "start_position": "beginning"
          }
        ]
      }
    }
  },
  "agent": {
    "region": "${region}",
    "logfile": "/var/log/amazon-cloudwatch-agent.log"
  }
}
CWEOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
