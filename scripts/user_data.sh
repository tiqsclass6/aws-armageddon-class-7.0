#!/bin/bash
set -Eeuo pipefail

echo "Starting user data script - $(date)"
trap 'echo "User data script completed (exit code $?) - $(date)"' EXIT

# IMDS readiness + IMDSv2 support
echo "Waiting for instance metadata service (IMDS)..."
until curl -s --max-time 2 http://169.254.169.254/latest/meta-data/ >/dev/null 2>&1; do
  sleep 2
done
echo "IMDS is reachable"

TOKEN="$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)"

imdscurl() {
  if [ -n "${TOKEN}" ]; then
    curl -sS -H "X-aws-ec2-metadata-token: ${TOKEN}" "$@"
  else
    curl -sS "$@"
  fi
}

DOC="$(imdscurl http://169.254.169.254/latest/dynamic/instance-identity/document || true)"
if [ -z "${DOC}" ]; then
  echo "ERROR: Could not read instance-identity document from IMDS. Check IMDS settings (IMDSv2 required?)"
  exit 1
fi

if command -v python3 >/dev/null 2>&1; then
  AWS_REGION="$(printf '%s' "${DOC}" | python3 -c 'import sys,json; print(json.load(sys.stdin)["region"])')"
else
  AWS_REGION="$(printf '%s' "${DOC}" | tr -d '\n' | sed -n 's/.*"region"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
fi

export AWS_REGION
echo "Detected AWS region: ${AWS_REGION}"

# App configuration
PREFIX="${PREFIX:-lab-1c}"
SECRET_ID="${SECRET_ID:-lab/rds/mysql_v5}"
export PREFIX SECRET_ID

echo "Using PREFIX=${PREFIX}"
echo "Using SECRET_ID=${SECRET_ID}"

echo "Checking VPC endpoint DNS resolution..."
for svc in ssm ssmmessages ec2messages logs secretsmanager kms; do
  if ! getent hosts "${svc}.${AWS_REGION}.amazonaws.com" >/dev/null 2>&1; then
    echo "WARN: ${svc}.${AWS_REGION}.amazonaws.com not resolvable (check Private DNS on endpoint)"
  fi
done
echo "Network checks complete"

###############################################################################
# NAT-less dependency install via OS repos (NO pip / NO public PyPI)
###############################################################################
# Goal: Private subnet works without NAT. Use dnf packages only.
# watchtower is optional; if not available, app logs only to journald/console.

echo "Installing Python runtime + required modules via dnf (NAT-less)..."

if ! command -v dnf >/dev/null 2>&1; then
  echo "ERROR: dnf not found. This script expects Amazon Linux 2023 / RHEL-family AMI."
  exit 1
fi

# Soft timeouts prevent long hangs in restricted networks
timeout 600 dnf -y update || echo "WARN: dnf update failed/timed out (continuing)"
timeout 600 dnf -y install python3 python3-pip || echo "WARN: python3/python3-pip install failed/timed out (continuing)"

# Install required Python modules from OS repos
timeout 600 dnf -y install \
  python3-boto3 \
  python3-flask \
  python3-pymysql \
  || echo "WARN: One or more python3-* packages not available in repo."

# Optional: watchtower (may not exist in AL2023 repos)
# If unavailable, app will still run; it will just skip CloudWatch logging via watchtower.
timeout 300 dnf -y install python3-watchtower 2>/dev/null || echo "INFO: python3-watchtower not available; CloudWatch logging via watchtower will be disabled."

echo "Validating Python imports..."
python3 - <<'PY'
import sys
missing = []
for m in ("boto3", "flask", "pymysql"):
    try:
        __import__(m)
    except Exception:
        missing.append(m)
if missing:
    print("ERROR: Missing Python modules after dnf install: " + ", ".join(missing))
    print("Fix: ensure repo mirror contains python3-boto3/python3-flask/python3-pymysql OR bake deps into AMI.")
    sys.exit(1)
print("OK: Required modules present: boto3, flask, pymysql")
try:
    import watchtower
    print("OK: watchtower present (CloudWatch logging enabled)")
except Exception:
    print("INFO: watchtower not present (CloudWatch logging disabled; journald still works).")
PY

# Application setup
mkdir -p /opt/rdsapp
cat > /opt/rdsapp/app.py << 'EOF'
import json
import os
import time
import logging
import boto3
import pymysql
from flask import Flask, request

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("rds-notes-app")

# Optional CloudWatch logging via watchtower (only if installed)
try:
    import watchtower
    cloudwatch_handler = watchtower.CloudWatchLogHandler(
        log_group_name=f"/aws/ec2/{os.environ.get('PREFIX', 'lab-1c')}-rds-app",
        stream_name=f"rdsapp-{int(time.time())}",
        send_interval=10,
        boto3_client=boto3.client("logs", region_name=os.environ.get("AWS_REGION"))
    )
    logger.addHandler(cloudwatch_handler)
    logger.info("Watchtower enabled: CloudWatch logging active")
except Exception as e:
    logger.warning("Watchtower disabled: %s", e)

console_handler = logging.StreamHandler()
console_handler.setFormatter(logging.Formatter('%(asctime)s [%(levelname)s] %(message)s'))
logger.addHandler(console_handler)

REGION = os.environ.get("AWS_REGION")
SECRET_ID = os.environ.get("SECRET_ID")

if not REGION:
    raise RuntimeError("AWS_REGION is not set")
if not SECRET_ID:
    raise RuntimeError("SECRET_ID is not set")

secrets_client = boto3.client("secretsmanager", region_name=REGION)

def get_db_creds():
    resp = secrets_client.get_secret_value(SecretId=SECRET_ID)
    return json.loads(resp["SecretString"])

def get_db_connection():
    creds = get_db_creds()
    return pymysql.connect(
        host=creds["host"],
        user=creds["username"],
        password=creds["password"],
        port=int(creds.get("port", 3306)),
        database=creds.get("dbname", "labdb"),
        autocommit=True,
        connect_timeout=10
    )

app = Flask(__name__)

@app.route("/")
def home():
    return """
    <h2>Private EC2 → RDS Notes App (Bonus A)</h2>
    <p><a href="/init">/init</a> – initialize database</p>
    <p>/add?note=hello</p>
    <p><a href="/list">/list</a></p>
    <small>Private subnet – access via SSM port forwarding</small>
    """

@app.route("/init")
def init_db():
    creds = get_db_creds()
    conn = pymysql.connect(
        host=creds["host"],
        user=creds["username"],
        password=creds["password"],
        port=int(creds.get("port", 3306)),
        autocommit=True
    )
    with conn.cursor() as cur:
        cur.execute("CREATE DATABASE IF NOT EXISTS labdb")
        cur.execute("USE labdb")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS notes (
              id INT AUTO_INCREMENT PRIMARY KEY,
              note VARCHAR(255),
              created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
    conn.close()
    logger.info("Database initialized successfully")
    return "Initialized labdb + notes table"

@app.route("/add")
def add_note():
    note = request.args.get("note", "").strip()
    if not note:
        return "note parameter required", 400
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("INSERT INTO notes (note) VALUES (%s)", (note,))
    logger.info("Note added: %s", note)
    return f"Added: {note}"

@app.route("/list")
def list_notes():
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id, note, created_at FROM notes ORDER BY id DESC")
            rows = cur.fetchall()
    return "<ul>" + "".join(f"<li>{r[0]} – {r[1]} ({r[2]})</li>" for r in rows) + "</ul>"

if __name__ == "__main__":
    logger.info("Starting app on port 8000")
    app.run(host="0.0.0.0", port=8000)
EOF

# systemd service (EnvironmentFile avoids substitution issues)
cat > /etc/rdsapp.env <<EOF
AWS_REGION=${AWS_REGION}
PREFIX=${PREFIX}
SECRET_ID=${SECRET_ID}
EOF
chmod 600 /etc/rdsapp.env

cat > /etc/systemd/system/rdsapp.service <<'EOF'
[Unit]
Description=RDS Notes Application (private)
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/opt/rdsapp
EnvironmentFile=/etc/rdsapp.env
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now rdsapp

echo "rdsapp service started successfully - $(date)"
