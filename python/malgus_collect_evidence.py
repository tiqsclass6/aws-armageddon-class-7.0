#!/usr/bin/env python3
import json, os, subprocess, sys, argparse, datetime, platform
from pathlib import Path
from typing import Any

# Reason why Darth Malgus would be pleased with this script.
# Malgus doesn't trust dashboards. He trusts artifacts. This script turns infrastructure into evidence.
# Reason why this script is relevant to your career.
# Audits, incidents, and regulated environments require reproducible proof—automation wins promotions.
# How you would talk about this script at an interview.
# "I built a multi-cloud evidence collector that outputs regulator-ready artifacts from AWS + GCP on demand."

# ==================== HELPER FUNCTIONS ====================

def run(cmd: list[str]) -> str:
    """Run command and return stdout or error message."""
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if p.returncode != 0:
        return f"ERROR running {' '.join(cmd)}\nSTDERR:\n{p.stderr}\nSTDOUT:\n{p.stdout}"
    return p.stdout.strip()

def write_file(path: Path, content: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content + "\n", encoding="utf-8")

def now_iso() -> str:
    """Modern UTC ISO timestamp (no deprecation warning)."""
    return datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

# ==================== PLATFORM-AWARE GCLOUD ====================

def get_gcloud_cmd() -> str:
    return "gcloud.cmd" if platform.system() == "Windows" else "gcloud"

def gcloud_json(args: list[str], project: str) -> Any:
    """Run gcloud with JSON output and parse it."""
    full_cmd = [get_gcloud_cmd()] + args + ["--project", project, "--format=json"]
    output = run(full_cmd)
    if output.startswith("ERROR"):
        return output
    try:
        return json.loads(output)
    except json.JSONDecodeError:
        return {"error": "Failed to parse JSON", "raw": output}

# ==================== AWS TOKYO ====================

def collect_aws_tokyo(outdir: Path, profile: str | None):
    region = "ap-northeast-1"
    env = os.environ.copy()
    if profile:
        env["AWS_PROFILE"] = profile

    def aws(args: list[str]) -> Any:
        cmd = ["aws"] + args + ["--region", region, "--output", "json"]
        output = run(cmd)
        if output.startswith("ERROR"):
            return output
        try:
            return json.loads(output)
        except json.JSONDecodeError:
            return output

    evidence = {"timestamp": now_iso(), "region": region, "checks": {}}

    evidence["checks"]["rds_instances_tokyo"] = aws(["rds", "describe-db-instances"])
    evidence["checks"]["tgw_list"]           = aws(["ec2", "describe-transit-gateways"])
    evidence["checks"]["vpn_connections"]    = aws(["ec2", "describe-vpn-connections"])
    evidence["checks"]["route_tables"]       = aws(["ec2", "describe-route-tables"])
    evidence["checks"]["security_groups"]    = aws(["ec2", "describe-security-groups"])

    # CloudTrail - limited in evidence, full dump to separate file
    cloudtrail_raw = run(["aws", "cloudtrail", "lookup-events", "--max-results", "10", "--region", region])
    evidence["checks"]["cloudtrail_recent"] = json.loads(cloudtrail_raw) if not cloudtrail_raw.startswith("ERROR") else cloudtrail_raw
    write_file(outdir / "cloudtrail_recent_full.json", cloudtrail_raw)

    write_file(outdir / "aws_evidence.json", json.dumps(evidence, indent=2, ensure_ascii=False))

    # Human-readable summaries
    write_file(outdir / "aws_vpn_connections.txt", json.dumps(evidence["checks"]["vpn_connections"], indent=2))
    write_file(outdir / "aws_routes.txt",          json.dumps(evidence["checks"]["route_tables"], indent=2))

# ==================== GCP NEW YORK / IOWA ====================

def collect_gcp_ny(outdir: Path, project: str, region: str):
    evidence = {"timestamp": now_iso(), "project": project, "region": region, "checks": {}}

    evidence["checks"]["mig_list"]             = gcloud_json(["compute", "instance-groups", "managed", "list", "--regions", region], project)
    evidence["checks"]["forwarding_rules"]     = gcloud_json(["compute", "forwarding-rules", "list", "--regions", region], project)
    evidence["checks"]["target_https_proxies"] = gcloud_json(["compute", "target-https-proxies", "list", "--regions", region], project)
    evidence["checks"]["backend_services"]     = gcloud_json(["compute", "backend-services", "list", "--regions", region], project)
    evidence["checks"]["health_checks"]        = gcloud_json(["compute", "health-checks", "list"], project)
    evidence["checks"]["firewall_rules"]       = gcloud_json(["compute", "firewall-rules", "list"], project)
    evidence["checks"]["vpn_tunnels"]          = gcloud_json(["compute", "vpn-tunnels", "list", "--regions", region], project)
    evidence["checks"]["routers"]              = gcloud_json(["compute", "routers", "list", "--regions", region], project)

    write_file(outdir / "gcp_evidence.json", json.dumps(evidence, indent=2, ensure_ascii=False))

    # Human-readable summaries (keep original style)
    write_file(outdir / "gcp_forwarding_rules.txt", json.dumps(evidence["checks"]["forwarding_rules"], indent=2))
    write_file(outdir / "gcp_firewall_rules.txt",   json.dumps(evidence["checks"]["firewall_rules"], indent=2))
    write_file(outdir / "gcp_vpn_tunnels.txt",      json.dumps(evidence["checks"]["vpn_tunnels"], indent=2))

# ==================== MAIN ====================

def main():
    ap = argparse.ArgumentParser(description="Malgus Evidence Collector - Clean structured output")
    ap.add_argument("--out", default="audit-pack", help="Output folder")
    ap.add_argument("--aws-profile", default=None)
    ap.add_argument("--gcp-project", default=None)
    ap.add_argument("--gcp-region", default="us-central1")
    ap.add_argument("--mode", choices=["aws-tokyo", "gcp-ny", "both"], default="both")
    args = ap.parse_args()

    base = Path(args.out)

    if args.mode in ("aws-tokyo", "both"):
        collect_aws_tokyo(base / "tokyo", args.aws_profile)

    if args.mode in ("gcp-ny", "both"):
        if not args.gcp_project:
            print("ERROR: --gcp-project is required for gcp-ny/both", file=sys.stderr)
            sys.exit(2)
        collect_gcp_ny(base / "ny", args.gcp_project, args.gcp_region)

    print(f"✅ Evidence written to: {base.resolve()}")

if __name__ == "__main__":
    main()