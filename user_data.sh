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
        <li><a href="https://theinternationalquietstorm.com" target="_blank">theinternationalquietstorm.com</a></li>
        <li><a href="https://app.theinternationalquietstorm.com" target="_blank">app.theinternationalquietstorm.com</a></li>
        <li><a href="https://www.theinternationalquietstorm.com" target="_blank">www.theinternationalquietstorm.com</a></li>
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

# Ensure lab entrypoint exists under /static for CloudFront caching/invalidation exercises
mkdir -p /var/www/html/static
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
