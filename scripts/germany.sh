#!/bin/bash
set -euo pipefail

# AL2023 uses dnf (yum is a shim)
dnf -y update

# Install Apache only (DO NOT install curl)
dnf -y install httpd

systemctl enable --now httpd

# IMDSv2 token (curl-minimal is sufficient)
TOKEN="$(curl -sS -m 3 -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)"

imds_get () {
  local path="$1"
  if [[ -n "${TOKEN}" ]]; then
    curl -sS -m 3 -H "X-aws-ec2-metadata-token: ${TOKEN}" "http://169.254.169.254/latest/${path}" || true
  else
    curl -sS -m 3 "http://169.254.169.254/latest/${path}" || true
  fi
}

local_ipv4="$(imds_get meta-data/local-ipv4)"
az="$(imds_get meta-data/placement/availability-zone)"
macid="$(imds_get meta-data/network/interfaces/macs/ | head -n 1 | tr -d '/')"
vpc=""
if [[ -n "${macid}" ]]; then
  vpc="$(imds_get meta-data/network/interfaces/macs/${macid}/vpc-id)"
fi
hostname_fqdn="$(hostname -f 2>/dev/null || hostname)"

# ---------- Write HTML ----------
cat > /var/www/html/index.html <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Germany Cloak - CloudFront Front Door</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <style>
    :root{
      --de-black:#111111;
      --de-red:#dd0000;
      --de-white:#ffffff;
      --de-yellow:#ffce00;

      --glass: rgba(0,0,0,.62);
      --glass2: rgba(0,0,0,.55);
      --shadow: 0 18px 60px rgba(0,0,0,.45);
    }

    body{
      margin:0;
      font-family: system-ui, Arial, sans-serif;
      color:#fff;
      background:
        linear-gradient(rgba(0,0,0,.68), rgba(0,0,0,.68)),
        url("https://images.alphacoders.com/516/516122.png")
        center/cover no-repeat fixed;
    }

    h1{
      margin: 22px 0 8px;
      letter-spacing: 1px;
      text-shadow: 0 0 14px rgba(0,0,0,0.95);
      text-align:center;
    }

    .sub{
      text-align:center;
      opacity:.9;
      margin: 0 0 18px;
      font-weight: 600;
    }

    .frame{
      position: relative;
      max-width: 1200px;
      margin: 18px auto 28px;
      border-radius: 18px;
      background: linear-gradient(90deg, var(--de-black), var(--de-red), var(--de-yellow));
      padding: 18px;
      box-shadow: var(--shadow);
      overflow: hidden;
    }

    .stage{
      position: relative;
      background: var(--glass);
      border-radius: 14px;
      padding: 18px;
      overflow: hidden;
    }

    .rail{
      position: absolute;
      top: 12px;
      bottom: 12px;
      width: 84px;
      border-radius: 14px;
      background: rgba(0,0,0,.42);
      backdrop-filter: blur(6px);
      overflow: hidden;
      box-shadow: inset 0 0 0 1px rgba(255,255,255,.08);
    }
    .rail.left{ left: 12px; }
    .rail.right{ right: 12px; }
    .rail .cap{
      position: absolute;
      top: 10px;
      left: 10px;
      right: 10px;
      padding: 10px 8px;
      border-radius: 12px;
      background: linear-gradient(180deg, rgba(255,255,255,.12), rgba(255,255,255,0));
      text-align: center;
      font-weight: 900;
      letter-spacing: .6px;
      font-size: 12px;
      color: rgba(255,255,255,.95);
      text-shadow:
        0 0 10px rgba(221, 0, 0, .70),
        0 0 14px rgba(255, 206, 0, .55),
        0 10px 18px rgba(0,0,0,.85);
      box-shadow:
        0 14px 26px rgba(0,0,0,.45),
        inset 0 0 0 1px rgba(255,255,255,.10);
    }
    .rail.left .cap{
      box-shadow:
        0 14px 26px rgba(0,0,0,.45),
        0 0 18px rgba(221, 0, 0, .35),
        inset 0 0 0 1px rgba(255,255,255,.10);
    }
    .rail.right .cap{
      box-shadow:
        0 14px 26px rgba(0,0,0,.45),
        0 0 18px rgba(255, 206, 0, .30),
        inset 0 0 0 1px rgba(255,255,255,.10);
    }

    .rail .scroll{
      position: absolute;
      top: 56px;
      left: 0;
      right: 0;
      bottom: 0;
      display: grid;
      place-items: center;
      overflow: hidden;
    }

    .marquee{
      width: 100%;
      height: 200%;
      display: grid;
      align-content: start;
      justify-items: center;
      gap: 18px;
      padding-top: 14px;
      will-change: transform;
    }

    .rail.left .marquee{
      transform-origin: center;
      transform: rotate(-90deg);
      animation: riseLeft 28s linear infinite;
    }
    .rail.right .marquee{
      transform-origin: center;
      transform: rotate(90deg);
      animation: riseRight 28s linear infinite;
    }

    .pill{
      width: 68px;
      height: 34px;
      border-radius: 999px;
      display: grid;
      place-items: center;
      font-weight: 900;
      font-size: 11px;
      letter-spacing: .6px;
      color: #0b0b0b;
      background: linear-gradient(90deg, var(--de-black), var(--de-red), var(--de-yellow));
      box-shadow: 0 10px 22px rgba(0,0,0,.35);
      text-transform: lowercase;
      user-select: none;
      white-space: nowrap;
    }

    @keyframes riseLeft{
      0%   { transform: rotate(-90deg) translateX(0); }
      100% { transform: rotate(-90deg) translateX(-50%); }
    }
    @keyframes riseRight{
      0%   { transform: rotate(90deg) translateX(0); }
      100% { transform: rotate(90deg) translateX(-50%); }
    }

    .content{
      margin: 0 104px;
    }

    .slideshow{
      position: relative;
      height: 440px;
      overflow: hidden;
      border-radius: 14px;
      background: rgba(0,0,0,.25);
      box-shadow:
        inset 0 0 0 1px rgba(255,255,255,.08),
        0 18px 44px rgba(0,0,0,.35);
    }

    .slide{
      position:absolute;
      inset:0;
      width:100%;
      height:100%;
      object-fit: contain;
      object-position: center;
      opacity:0;
      transition: opacity 1s ease;
      filter: saturate(1.05) contrast(1.05);
      background: rgba(0,0,0,.22);
    }
    .slide.active{ opacity: 1; }

    .slideshow::after{
      content:"";
      position:absolute;
      inset:0;
      pointer-events:none;
      background:
        radial-gradient(closest-side, rgba(0,0,0,0) 55%, rgba(0,0,0,.28) 100%);
    }

    .overlayTag{
      position:absolute;
      left: 18px;
      bottom: 18px;
      padding: 10px 14px;
      border-radius: 999px;
      background: rgba(0,0,0,.55);
      font-weight: 900;
      letter-spacing: .45px;
      border: 1px solid rgba(255,255,255,.12);
      box-shadow:
        0 14px 34px rgba(0,0,0,.35),
        0 0 10px rgba(221,0,0,.30),
        0 0 12px rgba(255,206,0,.24);
      color: rgba(255,255,255,.97);
      text-shadow:
        0 0 10px rgba(221, 0, 0, .70),
        0 0 14px rgba(255, 206, 0, .55),
        0 10px 18px rgba(0,0,0,.85);
    }

    .cards{
      display:grid;
      grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
      gap: 16px;
      margin-top: 18px;
    }

    .card{
      position: relative;
      background: var(--glass2);
      border-radius: 14px;
      padding: 16px;
      border: 1px solid rgba(255,255,255,.10);
      box-shadow: 0 16px 44px rgba(0,0,0,.22);
      overflow: hidden;
    }

    .card::before{
      content:"";
      position:absolute;
      left:0;
      top:0;
      bottom:0;
      width: 10px;
      background: linear-gradient(180deg, var(--de-red), var(--de-white), var(--de-yellow));
      opacity: .95;
    }

    .card h3, .kv{ padding-left: 10px; }

    .card h3{
      margin: 0 0 8px;
      letter-spacing: .5px;
    }

    .kv{
      display:grid;
      gap: 6px;
      margin: 10px 0 0;
      font-size: 14px;
      line-height: 1.35;
    }

    .kv ul{
      margin: 6px 0 0 18px;
      padding: 0;
    }

    .cards .card:nth-child(1){ color: var(--de-red); }
    .cards .card:nth-child(1) b{ color: var(--de-red); }
    .cards .card:nth-child(2){ color: var(--de-white); }
    .cards .card:nth-child(2) b{ color: var(--de-white); }
    .cards .card:nth-child(3){ color: var(--de-yellow); }
    .cards .card:nth-child(3) b{ color: var(--de-yellow); }
    .cards .card li{ color: currentColor; }

    .muted{ opacity: .92; }

    .btnRow{
      display:flex;
      justify-content: center;
      margin-top: 14px;
    }

    .btn{
      padding: 10px 18px;
      border-radius: 999px;
      border: none;
      font-weight: 900;
      cursor:pointer;
      background: linear-gradient(90deg, var(--de-black), var(--de-red), var(--de-yellow));
      color: #0b0b0b;
      box-shadow: 0 18px 46px rgba(0,0,0,.28);
    }

    .foot{
      text-align:center;
      opacity:.9;
      font-size: 12px;
      margin-top: 14px;
      color: #fff;
    }
  </style>
</head>

<body>
  <h1>Germany Cloak • CloudFront Front Door</h1>
  <div class="sub">“Only the front door is visible. Everything behind it stays private.”</div>

  <div class="frame">

    <div class="rail left" aria-hidden="true">
      <div class="cap" id="leftCap"><b>EDGE: us-east-1</b></div>
      <div class="scroll">
        <div class="marquee" id="leftMarquee"></div>
      </div>
    </div>

    <div class="rail right" aria-hidden="true">
      <div class="cap" id="rightCap"><b>ORIGIN: us-east-2</b></div>
      <div class="scroll">
        <div class="marquee" id="rightMarquee"></div>
      </div>
    </div>

    <div class="stage">
      <div class="content">

        <div class="slideshow">
          <img class="slide active" id="slide0" alt="Germany slide 1">
          <img class="slide" id="slide1" alt="Germany slide 2">
          <img class="slide" id="slide2" alt="Germany slide 3">
          <div class="overlayTag" id="tagLine">CLOAK ACTIVE • CloudFront → ALB (Header-Gated)</div>
        </div>

        <div class="btnRow">
          <button class="btn" onclick="rotateNow()">Rotate Visuals</button>
        </div>

        <div class="cards">
          <div class="card">
            <h3>Front Door (CloudFront)</h3>
            <div class="kv">
              <div><b>Aliases:</b>
                <ul>
                  <li><a href="https://theinternationalquietstorm.com" target="_blank" rel="noopener noreferrer"><b>theinternationalquietstorm.com</b></a></li>
                  <li><a href="https://app.theinternationalquietstorm.com" target="_blank" rel="noopener noreferrer"><b>app.theinternationalquietstorm.com</b></a></li>
                </ul>
              </div>
              <div><b>WAF Scope:</b> CLOUDFRONT</div>
              <div class="muted"><b>Goal:</b>
                <ul>
                  <li>Direct ALB access fails</li>
                  <li>CloudFront succeeds.</li>
                </ul>
              </div>
            </div>
          </div>

          <div class="card">
            <h3>AWS Instance Details</h3>
            <div class="kv"></div>
            <p><b>Instance:</b> ${hostname_fqdn}</p>
            <p><b>Private IP:</b> ${local_ipv4}</p>
            <p><b>AZ:</b> ${az}</p>
            <p><b>VPC:</b> ${vpc}</p>
          </div>

          <div class="card">
            <h3>Behind the Curtain (Origin)</h3>
            <div class="kv">
              <div><b>Origin:</b> ALB (HTTPS)</div>
              <div><b>Listener:</b>
                <ul>
                  <li>default 403</li>
                  <li>rule allows only correct header</li>
                </ul>
              </div>
              <div><b>Private:</b> Web instances in Private Subnets</div>
              <div class="muted"><b>Note:</b> The ALB cert won’t match the <b>*.elb.amazonaws.com</b> hostname (expected).</div>
            </div>
          </div>
        </div>

        <div class="foot"><b>Tip: for Windows curl, use <code>--ssl-no-revoke</code> if schannel revocation checks fail in your terminal window.</b></div>

      </div>
    </div>
  </div>

  <script>
    const images = [
      "https://img.dizkover.com/upload/img/orig/111-152151284965-lorena-rae.jpg",
      "https://cdn.imgsearch.com/batches/4/thumbnails/md/839521.webp?token=75pvl452bRLaikB8aQaroqBO83TAb09qKXbnMTU_LPQ&expires=9999999999",
      "https://mediaslide-europe.storage.googleapis.com/mostwanted/pictures/4007/16593/large-1706708329-1030d3a6e87bbe299049597bc0ba0a9c.jpg"
    ];

    const slides = [
      document.getElementById("slide0"),
      document.getElementById("slide1"),
      document.getElementById("slide2")
    ];
    slides.forEach((s, i) => s.src = images[i]);

    let slideIdx = 0;

    function rotateSlides(){
      slides[slideIdx].classList.remove("active");
      slideIdx = (slideIdx + 1) % slides.length;
      slides[slideIdx].classList.add("active");
    }

    function rotateNow(){
      rotateSlides();
      pulseTag();
    }

    setInterval(() => {
      rotateSlides();
      pulseTag();
    }, 10000);

    function pulseTag(){
      const tag = document.getElementById("tagLine");
      tag.style.transform = "scale(1.03)";
      setTimeout(() => tag.style.transform = "scale(1)", 180);
    }

    // Keep regions fixed (us-east-1 left, us-east-2 right)
    const leftMarquee  = document.getElementById("leftMarquee");
    const rightMarquee = document.getElementById("rightMarquee");

    function fillMarquee(el, text){
      el.innerHTML = "";
      const pills = [];
      for(let i=0;i<26;i++){
        const d = document.createElement("div");
        d.className = "pill";
        d.textContent = text;
        pills.push(d);
      }
      pills.concat(pills).forEach(p => el.appendChild(p.cloneNode(true)));
    }

    fillMarquee(leftMarquee, "us-east-1");
    fillMarquee(rightMarquee, "us-east-2");
  </script>
</body>
</html>
EOF