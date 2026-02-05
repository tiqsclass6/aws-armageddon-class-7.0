#!/usr/bin/env python3
"""
malgus_cloudfront_log_explainer.py

Counts CloudFront cache outcomes (Hit / Miss / RefreshHit) from CloudFront *standard logs*
stored in S3 (tab-delimited, often .gz).

# Reason why Darth Malgus would be pleased with this script:
# The Empire doesn’t argue with feelings. It counts outcomes. Hit. Miss. RefreshHit. Evidence only.

# Reason why this script is relevant to your career:
# Cache behavior = latency + cost + origin stability. Being able to prove Hit/Miss rates is platform engineering reality.

# How you would talk about this script at an interview:
# “I wrote a small S3-backed log analyzer that downloads recent CloudFront standard logs,
#  parses x-edge-result-type, and reports Hit/Miss/RefreshHit metrics to validate caching policy.”
"""

import argparse
import gzip
import io
import os
import subprocess
import sys
import tempfile
from collections import Counter
from typing import Dict, List, Optional

TARGETS = {"Hit", "Miss", "RefreshHit"}

def run(cmd: List[str]) -> str:
    """Run a command and return stdout; raise with clear error if it fails."""
    try:
        p = subprocess.run(cmd, check=True, capture_output=True, text=True)
        return p.stdout
    except FileNotFoundError:
        raise RuntimeError("Command not found. Install AWS CLI v2 and ensure 'aws' is on PATH.")
    except subprocess.CalledProcessError as e:
        msg = e.stderr.strip() or e.stdout.strip() or str(e)
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{msg}")

def aws_s3_ls_recursive(bucket: str, prefix: str) -> List[str]:
    """Return object keys from aws s3 ls --recursive"""
    output = run(["aws", "s3", "ls", f"s3://{bucket}/{prefix}", "--recursive"])
    keys = []
    for line in output.splitlines():
        if line.strip():
            parts = line.split()
            if len(parts) >= 4:
                key = " ".join(parts[3:])
                keys.append(key)
    return keys

def pick_latest(keys: List[str], n: int) -> List[str]:
    """Sort keys by timestamp (assumes filename format has timestamp) and take latest n"""
    # Simple sort assuming timestamp is in filename (CloudFront format)
    sorted_keys = sorted(keys, reverse=True)  # newest first
    return sorted_keys[:n]

def aws_s3_cp(bucket: str, key: str, dest: str):
    """Download file from S3"""
    run(["aws", "s3", "cp", f"s3://{bucket}/{key}", dest])

def count_standard_log_files(files: List[str]) -> Dict[str, int]:
    counts = Counter()
    total = 0

    for filepath in files:
        try:
            with gzip.open(filepath, 'rt') if filepath.endswith('.gz') else open(filepath, 'r') as f:
                for line in f:
                    if line.strip() and not line.startswith('#'):
                        fields = line.split('\t')
                        if len(fields) >= 13:
                            result_type = fields[8]  # x-edge-result-type is usually index 8
                            if result_type in TARGETS:
                                counts[result_type] += 1
                                total += 1
                            else:
                                counts[f"Other:{result_type}"] += 1
        except Exception as e:
            print(f"Warning: Could not parse {filepath}: {e}", file=sys.stderr)

    return {"counts": dict(counts), "total_core": total}

def print_report(counts: Dict):
    core = counts.get("counts", {})
    total_core = counts.get("total_core", 0)

    print("\n=== CloudFront Cache Outcome Report (Standard Logs) ===")
    print(f"Core total (Hit/Miss/RefreshHit): {total_core}")
    print(f"All counted lines/notes:          {sum(core.values())}")
    print("\nCore outcomes:")
    for k in TARGETS:
        v = core.get(k, 0)
        pct = round(v / total_core * 100, 1) if total_core > 0 else 0.0
        print(f"  {k:<12} {v:>5}   ({pct:>5.1f}% of core)")

    print("\nOther outcomes / parsing notes (top 20):")
    for k, v in sorted(core.items(), key=lambda x: x[1], reverse=True):
        if not k.startswith("Other:"):
            continue
        print(f"  {k:<30} {v}")

    print("\nInterpretation (ops):")
    print("  • High Hit% usually means lower latency & lower origin load.")
    print("  • High Miss% suggests caching policy mismatch, uncacheable headers,")
    print("    query-string/cookie variance, or origin Cache-Control behavior.")
    print("  • RefreshHit means CloudFront revalidated with origin and served cached content (often good).")
    print("=======================================================")

def main() -> int:
    ap = argparse.ArgumentParser(description="Count Hit/Miss/RefreshHit from CloudFront standard logs in S3.")
    ap.add_argument("--bucket", default="lab-3b-cloudfront-logs", help="S3 bucket name")
    ap.add_argument("--prefix", default="lab-3b/", help="S3 prefix (folder)")
    ap.add_argument("--latest", type=int, default=5, help="Analyze the latest N log files")
    ap.add_argument("--keep", action="store_true", help="Keep downloaded files")
    args = ap.parse_args()

    try:
        keys = aws_s3_ls_recursive(args.bucket, args.prefix)
        if not keys:
            print(f"ERROR: No log files found in s3://{args.bucket}/{args.prefix}")
            print("   → Verify bucket and prefix exist:")
            print(f"     aws s3 ls s3://{args.bucket}/{args.prefix} --recursive")
            print("   → Ensure CloudFront logging is enabled and some traffic has been sent.")
            return 1

        latest_keys = pick_latest(keys, args.latest)
        print(f"Found {len(keys)} objects. Analyzing latest {len(latest_keys)}:")
        for k in latest_keys:
            print(f"  - s3://{args.bucket}/{k}")

        tmpdir = tempfile.mkdtemp(prefix="malgus_cf_")
        downloaded = []
        try:
            for k in latest_keys:
                filename = os.path.basename(k) or "log"
                dest = os.path.join(tmpdir, filename)
                aws_s3_cp(args.bucket, k, dest)
                downloaded.append(dest)

            counts = count_standard_log_files(downloaded)
            print_report(counts)

            if args.keep:
                print(f"\nKept downloaded files in: {tmpdir}")
            else:
                for p in downloaded:
                    try:
                        os.remove(p)
                    except OSError:
                        pass
                try:
                    os.rmdir(tmpdir)
                except OSError:
                    pass

            return 0
        except RuntimeError as e:
            print(str(e), file=sys.stderr)
            print("\nQuick checks:")
            print("  aws sts get-caller-identity")
            print(f"  aws s3 ls s3://{args.bucket}/{args.prefix} --recursive | tail -n 20")
            return 1
    except Exception as e:
        print(f"Unexpected error: {str(e)}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())