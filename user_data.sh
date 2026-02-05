#!/bin/bash
set -euo pipefail

# Packages
dnf -y install amazon-ssm-agent || true
systemctl daemon-reload || true
systemctl enable amazon-ssm-agent || true
systemctl restart amazon-ssm-agent || true
systemctl status amazon-ssm-agent --no-pager || true

dnf -y install httpd
systemctl enable --now httpd

# Apache CGI Config
cat > /etc/httpd/conf.d/api.conf <<'EOF'
ScriptAlias /api/ "/var/www/cgi-bin/api/"
ScriptAlias /meta/ "/var/www/cgi-bin/meta/"

<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options +ExecCGI -Indexes
    Require all granted
</Directory>
EOF

mkdir -p /var/www/cgi-bin/api
mkdir -p /var/www/cgi-bin/meta

# Front Page
cat > /var/www/html/index.html <<'EOF'
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Germany Cloak - CloudFront Front Door</title>
<meta name="viewport" content="width=device-width, initial-scale=1">

<style>
body{
  margin:0;
  font-family: system-ui, Arial, sans-serif;
  color:#fff;
  background:
    linear-gradient(rgba(0,0,0,.68), rgba(0,0,0,.68)),
    url("https://images.alphacoders.com/516/516122.png")
    center/cover no-repeat fixed;
}
h1{text-align:center;margin-top:20px;}
.sub{text-align:center;opacity:.9;margin-bottom:20px;}
.box{
  max-width:1100px;
  margin:0 auto 40px;
  background:rgba(0,0,0,.55);
  border-radius:16px;
  padding:20px;
  box-shadow:0 18px 50px rgba(0,0,0,.45);
}
.cards{
  display:grid;
  grid-template-columns:repeat(auto-fit,minmax(260px,1fr));
  gap:16px;
}
.card{
  background:rgba(0,0,0,.55);
  border-radius:14px;
  padding:16px;
  border:1px solid rgba(255,255,255,.1);
}
a{color:#ffce00;text-decoration:none;font-weight:700;}
</style>
</head>

<body>
<h1>Germany Cloak • CloudFront Front Door</h1>
<div class="sub">“Only the front door is visible. Everything behind it stays private.”</div>

<div class="box">
  <div class="cards">

    <div class="card">
      <h3>Front Door (CloudFront)</h3>
      <ul>
        <li><a href="https://app.theinternationalquietstorm.com" target="_blank">app.theinternationalquietstorm.com</a></li>
        <li><a href="https://origin.theinternationalquietstorm.com" target="_blank">origin.theinternationalquietstorm.com</a></li>
      </ul>
      <p><b>Goal:</b> Direct ALB access fails, CloudFront succeeds.</p>
    </div>

    <div class="card">
      <h3>Instance Metadata</h3>
      <p><b>Instance ID:</b> <span id="iid">loading...</span></p>
      <p><b>Private IP:</b> <span id="ip">loading...</span></p>
      <p><b>AZ:</b> <span id="az">loading...</span></p>
      <p><b>Region:</b> <span id="region">loading...</span></p>
    </div>

    <div class="card">
      <h3>Behind the Curtain (Origin)</h3>
      <ul>
        <li>ALB (HTTPS)</li>
        <li>Header-gated listener rule</li>
        <li>Private subnets only</li>
        <li>CloudFront = only public ingress</li>
      </ul>
    </div>

  </div>
</div>

<script>
async function meta(path){
  try{
    const r = await fetch("/meta/" + path);
    return await r.text();
  }catch(e){ return "unavailable"; }
}

(async ()=>{
  document.getElementById("iid").innerText    = await meta("instance-id");
  document.getElementById("ip").innerText     = await meta("local-ipv4");
  document.getElementById("az").innerText     = await meta("placement/availability-zone");
  document.getElementById("region").innerText = await meta("placement/region");
})();
</script>
</body>
</html>
EOF

mkdir -p /var/www/html/static
mkdir -p /var/www/cgi-bin/static

# Store the "body" separately so you can change content without changing the CGI logic
cp -f /var/www/html/index.html /var/www/html/static/index.body
echo "tiqs-v1" > /etc/tiqs_etag
echo "30"       > /etc/tiqs_max_age

# Map EXACTLY /static/index.html to our CGI handler (so /static/* behavior applies in CloudFront)
cat > /etc/httpd/conf.d/tiqs-static.conf <<'EOF'
# Route only /static/index.html through CGI so we can control validators precisely.
ScriptAliasMatch ^/static/index\.html$ /var/www/cgi-bin/static/index

<Directory "/var/www/cgi-bin/static">
    AllowOverride None
    Options +ExecCGI -Indexes
    Require all granted
</Directory>
EOF

# CGI handler for /static/index.html
cat > /var/www/cgi-bin/static/index <<'EOF'
#!/bin/bash
set -euo pipefail

BODY_FILE="/var/www/html/static/index.body"
ETAG_FILE="/etc/tiqs_etag"
MAXAGE_FILE="/etc/tiqs_max_age"

ETAG="$(cat "${ETAG_FILE}" 2>/dev/null || echo 'tiqs-v1')"
MAXAGE="$(cat "${MAXAGE_FILE}" 2>/dev/null || echo '30')"

# Last-Modified from the body file mtime (RFC 7231 IMF-fixdate)
LAST_MOD="$(LC_ALL=C date -u -r "${BODY_FILE}" '+%a, %d %b %Y %H:%M:%S GMT' 2>/dev/null || true)"

# Read conditional headers from the environment (Apache passes them as HTTP_* vars)
IF_NONE_MATCH="${HTTP_IF_NONE_MATCH:-}"
IF_MOD_SINCE="${HTTP_IF_MODIFIED_SINCE:-}"

# Basic If-None-Match match (handles quoted and unquoted)
etag_matches=false
if [[ -n "${IF_NONE_MATCH}" ]]; then
  # If-None-Match may contain multiple values: W/"x", "y", *
  if echo "${IF_NONE_MATCH}" | grep -qE "(^|,)[[:space:]]*\"?${ETAG}\"?([[:space:]]*,|$)"; then
    etag_matches=true
  fi
  if echo "${IF_NONE_MATCH}" | grep -qE "(^|,)[[:space:]]*\*([[:space:]]*,|$)"; then
    etag_matches=true
  fi
fi

# If-Modified-Since check (coarse: if header equals our Last-Modified, treat as not modified)
ims_matches=false
if [[ -n "${IF_MOD_SINCE}" && -n "${LAST_MOD}" ]]; then
  # Some clients append ; length=... so compare prefix
  if [[ "${IF_MOD_SINCE}" == "${LAST_MOD}"* ]]; then
    ims_matches=true
  fi
fi

# If either validator indicates not modified, return 304
if [[ "${etag_matches}" == "true" || "${ims_matches}" == "true" ]]; then
  echo "Status: 304 Not Modified"
  echo "Cache-Control: public, max-age=${MAXAGE}"
  echo "ETag: \"${ETAG}\""
  [[ -n "${LAST_MOD}" ]] && echo "Last-Modified: ${LAST_MOD}"
  echo "Content-Type: text/html; charset=utf-8"
  echo ""
  exit 0
fi

# Otherwise return 200 with body + validators
echo "Content-Type: text/html; charset=utf-8"
echo "Cache-Control: public, max-age=${MAXAGE}"
echo "ETag: \"${ETAG}\""
[[ -n "${LAST_MOD}" ]] && echo "Last-Modified: ${LAST_MOD}"
echo ""

cat "${BODY_FILE}"
EOF
chmod 755 /var/www/cgi-bin/static/index

# Keep a real file in place as a fallback/visibility artifact (CGI will handle the exact /static/index.html path)
cp -f /var/www/html/index.html /var/www/html/static/index.html

# Metadata Proxy (Browser Safe)
cat > /var/www/cgi-bin/meta/index <<'EOF'
#!/bin/bash
PATH_INFO="${PATH_INFO#/}"

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")

echo "Content-Type: text/plain"
echo ""

curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  "http://169.254.169.254/latest/meta-data/${PATH_INFO}"
EOF
chmod 755 /var/www/cgi-bin/meta/index

# API: /api/list  (PRIVATE, NO CACHE)
cat > /var/www/cgi-bin/api/list <<'EOF'
#!/bin/bash

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")

IID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/region)

echo "Content-Type: text/plain"
echo "Cache-Control: private, no-store"
echo ""

echo "SERVICE=theinternationalquietstorm.com"
echo "ENDPOINT=/api/list"
echo "API_LIST_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "INSTANCE_ID=${IID}"
echo "REGION=${REGION}"
echo "EPOCH=$(date +%s)"
echo "RAND=$RANDOM"
EOF
chmod 755 /var/www/cgi-bin/api/list

# API: /api/public-feed (PUBLIC CACHE SAFE)
cat > /var/www/cgi-bin/api/public-feed <<'EOF'
#!/bin/bash

server_time_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
motm="$(date -u +%Y-%m-%dT%H:%MZ)"

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 60")

IID=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)

REGION=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/region)

echo "Content-Type: application/json"
echo "Cache-Control: public, s-maxage=30, max-age=0"
echo ""

cat <<JSON
{
  "service": "theinternationalquietstorm.com",
  "endpoint": "/api/public-feed",
  "server_time_utc": "${server_time_utc}",
  "message_of_the_minute": "${motm}",
  "instance_id": "${IID}",
  "region": "${REGION}"
}
JSON
EOF

chmod 755 /var/www/cgi-bin/api/public-feed
systemctl restart httpd
