#!/bin/bash
set -Eeuo pipefail

LOG_FILE="/var/log/user-data-rdsapp.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting user data script - $(date -u)"
trap 'rc=$?; echo "User data script completed (exit code $rc) - $(date -u)"; exit $rc' EXIT

# IMDSv2 helpers (no curl deps besides curl itself)
echo "Waiting for IMDS..."
until curl -s --max-time 2 http://169.254.169.254/latest/meta-data/ >/dev/null 2>&1; do
  sleep 2
done
echo "IMDS is reachable"

TOKEN="$(curl -sS -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)"

imdscurl() {
  if [ -n "${TOKEN:-}" ]; then
    curl -sS -H "X-aws-ec2-metadata-token: ${TOKEN}" "$@"
  else
    curl -sS "$@"
  fi
}

DOC="$(imdscurl http://169.254.169.254/latest/dynamic/instance-identity/document || true)"
if [ -z "${DOC}" ]; then
  echo "ERROR: Could not read instance-identity document from IMDS."
  exit 1
fi

AWS_REGION="$(printf '%s' "${DOC}" | python3 -c 'import sys,json; print(json.load(sys.stdin)["region"])' 2>/dev/null || true)"
if [ -z "${AWS_REGION}" ]; then
  AWS_REGION="$(printf '%s' "${DOC}" | tr -d '\n' | sed -n 's/.*"region"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
fi
if [ -z "${AWS_REGION}" ]; then
  echo "ERROR: Failed to determine AWS region from IMDS document."
  exit 1
fi

export AWS_REGION
echo "Detected AWS region: ${AWS_REGION}"

# App configuration
PREFIX="${PREFIX:-lab-2a}"
SECRET_ID="${SECRET_ID:-lab/rds/mysql_v26}"

# REQUIRED for offline wheel install
PIP_WHEEL_S3_BUCKET="${PIP_WHEEL_S3_BUCKET:-lab-2a-wheels-866340886126}"
PIP_WHEEL_S3_PREFIX="${PIP_WHEEL_S3_PREFIX:-wheels}"

export PREFIX SECRET_ID PIP_WHEEL_S3_BUCKET PIP_WHEEL_S3_PREFIX

echo "Using PREFIX=${PREFIX}"
echo "Using SECRET_ID=${SECRET_ID}"
echo "Using PIP_WHEEL_S3_BUCKET=${PIP_WHEEL_S3_BUCKET}"
echo "Using PIP_WHEEL_S3_PREFIX=${PIP_WHEEL_S3_PREFIX}"

# Basic network checks (private DNS for endpoints)
echo "Checking VPC endpoint DNS resolution..."
for svc in ssm ssmmessages ec2messages logs secretsmanager kms s3; do
  if ! getent hosts "${svc}.${AWS_REGION}.amazonaws.com" >/dev/null 2>&1; then
    echo "WARN: ${svc}.${AWS_REGION}.amazonaws.com not resolvable (endpoint Private DNS?)"
  fi
done
echo "Network checks complete"

# Install deps via dnf (private subnet safe)
if ! command -v dnf >/dev/null 2>&1; then
  echo "ERROR: dnf not found. This script expects Amazon Linux 2023."
  exit 1
fi

echo "Installing dependencies via dnf..."
timeout 600 dnf -y update || echo "WARN: dnf update failed/timed out (continuing)"
timeout 600 dnf -y install \
  python3 python3-pip \
  python3-boto3 python3-flask \
  awscli \
  libcap unzip ca-certificates \
  || echo "WARN: dnf install had issues (continuing)"

# Ensure pip exists
python3 -m pip --version >/dev/null 2>&1 || { echo "ERROR: pip not available after install"; exit 1; }

# Offline install: PyMySQL wheel from S3
# Requires: instance profile has s3:GetObject to that bucket + S3 gateway endpoint exists
WHEEL_DIR="/opt/wheels"
mkdir -p "${WHEEL_DIR}"
chmod 755 "${WHEEL_DIR}"

echo "Fetching PyMySQL wheel from S3 (offline install path)..."
WHEEL_KEY="${PIP_WHEEL_S3_PREFIX%/}/PyMySQL-1.1.0-py3-none-any.whl"

# Use awscli from dnf (no dependency on your broken Windows CLI)
if ! aws s3 cp "s3://${PIP_WHEEL_S3_BUCKET}/${WHEEL_KEY}" "${WHEEL_DIR}/PyMySQL-1.1.0-py3-none-any.whl" --region "${AWS_REGION}"; then
  echo "ERROR: Failed to download wheel from s3://${PIP_WHEEL_S3_BUCKET}/${WHEEL_KEY}"
  echo "Check: bucket policy, instance role permissions, and S3 gateway endpoint route."
  exit 1
fi

ls -la "${WHEEL_DIR}"

echo "Installing PyMySQL from local wheel (no-index)..."
python3 -m pip install --no-index --find-links "${WHEEL_DIR}" "PyMySQL==1.1.0"

echo "Validating Python imports..."
python3 - <<'PY'
import sys
missing = []
for m in ("boto3", "flask", "pymysql"):
    try:
        __import__(m)
    except Exception as e:
        missing.append((m, str(e)))
if missing:
    print("ERROR: Missing Python modules:")
    for m, e in missing:
        print(f" - {m}: {e}")
    sys.exit(1)
print("OK: boto3, flask, pymysql imports succeeded")
PY

# Allow binding to port 80 as non-root
if command -v setcap >/dev/null 2>&1; then
  REAL_PYTHON="$(readlink -f /usr/bin/python3)"
  setcap 'cap_net_bind_service=+ep' "$REAL_PYTHON" || echo "WARN: setcap failed; may need root for port 80"
else
  echo "WARN: setcap not present; may need root for port 80"
fi

# App setup
mkdir -p /opt/rdsapp

cat > /opt/rdsapp/app.py <<'EOF'
import json
import os
import time
import logging
import boto3
import pymysql
from flask import Flask, request

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("rds-notes-app")

REGION = os.environ.get("AWS_REGION")
SECRET_ID = os.environ.get("SECRET_ID")
PREFIX = os.environ.get("PREFIX", "lab-2a")

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
        connect_timeout=10,
    )

app = Flask(__name__)

@app.route("/")
def home():
    return f"""
    <h2>Private EC2 → RDS Notes App (Lab 2A CloudFront → ALB)</h2>
    <p><b>Prefix:</b> {PREFIX}</p>
    <p><a href="/init">/init</a> – initialize database</p>
    <p>/add?note=hello</p>
    <p><a href="/list">/list</a></p>
    <p><a href="/health">/health</a></p>
    """

@app.route("/health")
def health():
    return "OK", 200

@app.route("/init")
def init_db():
    try:
        creds = get_db_creds()
        logger.info("Retrieved credentials from Secrets Manager")
        conn = pymysql.connect(
            host=creds["host"],
            user=creds["username"],
            password=creds["password"],
            port=int(creds.get("port", 3306)),
            database=creds.get("dbname", "labdb"),
            autocommit=True,
            connect_timeout=10,
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
    except Exception as e:
        logger.exception("Error in /init: %s", str(e))
        return f"Error during initialization: {str(e)}", 500

@app.route("/add")
def add_note():
    try:
        note = request.args.get("note", "").strip()
        if not note:
            return "note parameter required", 400
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("INSERT INTO notes (note) VALUES (%s)", (note,))
        logger.info("Note added: %s", note)
        return f"Added: {note}"
    except Exception as e:
        logger.exception("Error in /add: %s", str(e))
        return f"Error: {str(e)}", 500

@app.route("/list")
def list_notes():
    try:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT id, note, created_at FROM notes ORDER BY id DESC")
                rows = cur.fetchall()
        return "<ul>" + "".join(f"<li>{r[0]} – {r[1]} ({r[2]})</li>" for r in rows) + "</ul>"
    except Exception as e:
        logger.exception("Error in /list: %s", str(e))
        return f"Error: {str(e)}", 500

if __name__ == "__main__":
    logger.info("Starting app on port 80")
    app.run(host="0.0.0.0", port=80)
EOF

# Environment file for systemd
cat > /etc/rdsapp.env <<EOF
AWS_REGION=${AWS_REGION}
PREFIX=${PREFIX}
SECRET_ID=${SECRET_ID}
EOF
chmod 600 /etc/rdsapp.env

# systemd unit
cat > /etc/systemd/system/rdsapp.service <<'EOF'
[Unit]
Description=RDS Notes Application (private subnet + CloudFront/ALB)
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/opt/rdsapp
EnvironmentFile=/etc/rdsapp.env
ExecStart=/usr/bin/python3 /opt/rdsapp/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now rdsapp
echo "Service status:"
systemctl --no-pager status rdsapp || true
echo "Listening ports:"
ss -lntp | egrep ':80' || true
echo "Local health check:"
curl -sS -D- http://127.0.0.1/health || true