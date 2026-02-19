#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# gate_secrets_and_role.sh
#
# Located in: scripts/
# Outputs to: ./scripts-results/gate_secrets_and_role.json
# ============================================================

# ---------- Defaults (override via env or flags) ----------
REGION="${REGION:-us-east-1}"                                                                                      # AWS region for API calls
INSTANCE_ID="${INSTANCE_ID:-i-07545b8bea0fa9d59}"                                                                  # EC2 instance ID to check
SECRET_ID="${SECRET_ID:-arn:aws:secretsmanager:us-east-1:866340886126:secret:lab/rds/mysql_v26-??????}"            # Secrets Manager secret ARN
DB_ID="${DB_ID:-lab-1c-mysql}"                                                                                     # RDS DB instance identifier

# toggles pass-through
REQUIRE_ROTATION="${REQUIRE_ROTATION:-false}"                                                                      # Whether to require recent rotation
CHECK_SECRET_POLICY_WILDCARD="${CHECK_SECRET_POLICY_WILDCARD:-true}"                                               # Whether to check for wildcard permissions in secret policy
CHECK_SECRET_VALUE_READ="${CHECK_SECRET_VALUE_READ:-true}"                                                         # Whether to check if secret value can be read
EXPECTED_ROLE_NAME="${EXPECTED_ROLE_NAME:-lab-1c-ec2-ssm-role}"                                                    # Expected IAM role name to be attached to instance

# ---------- Helpers ----------
now_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

failures=()
warnings=()
details=()

add_detail() { details+=("$1"); }
add_warning() { warnings+=("$1"); }
add_failure() { failures+=("$1"); }

usage() {
  cat <<EOF
Usage:
  REGION=us-east-1 INSTANCE_ID=i-07545b8bea0fa9d59 SECRET_ID=arn:aws:secretsmanager:us-east-1:866340886126:secret:lab/rds/mysql_v26-?????? scripts/gate_secrets_and_role.sh

Required:
  REGION        AWS region (default: us-east-1)
  INSTANCE_ID   EC2 instance id to check (required)
  SECRET_ID     Secrets Manager secret name or ARN (required)

Optional toggles (env vars):
  REQUIRE_ROTATION=true|false                (default: false)
  CHECK_SECRET_POLICY_WILDCARD=true|false    (default: true)
  CHECK_SECRET_VALUE_READ=true|false         (default: false)
  EXPECTED_ROLE_NAME=...                     (default: resolved from instance profile)
  OUT_JSON=...                               (default: ./scripts-results/gate_secrets_and_role.json)
EOF
}

# ---------- Args (optional) ----------
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

# ---------- Preconditions ----------
if ! have_cmd aws; then
  echo "ERROR: aws CLI not found on PATH." >&2
  exit 1
fi

if ! have_cmd jq; then
  echo "ERROR: jq not found on PATH. Please install jq to generate clean JSON output." >&2
  exit 1
fi

if [[ -z "$INSTANCE_ID" || -z "$SECRET_ID" ]]; then
  echo "ERROR: INSTANCE_ID and SECRET_ID are required." >&2
  usage >&2
  exit 1
fi

# ---------- Check 0: identity sanity ----------
if aws sts get-caller-identity --region "$REGION" >/dev/null 2>&1; then
  add_detail "PASS: aws sts get-caller-identity succeeded (credentials OK)."
else
  add_failure "FAIL: aws sts get-caller-identity failed (credentials/permissions)."
fi

# ---------- Check 1: secret exists ----------
if aws secretsmanager describe-secret --secret-id "$SECRET_ID" --region "$REGION" >/dev/null 2>&1; then
  add_detail "PASS: secret exists and is describable ($SECRET_ID)."
else
  add_failure "FAIL: cannot describe secret ($SECRET_ID). It may not exist or you lack permission."
fi

# ---------- Check 2: rotation (optional strict) ----------
if [[ "$REQUIRE_ROTATION" == "true" ]]; then
  rot="$(aws secretsmanager describe-secret --secret-id "$SECRET_ID" --region "$REGION" \
    --query "RotationEnabled" --output text 2>/dev/null || echo "Unknown")"
  if [[ "$rot" == "True" ]]; then
    add_detail "PASS: secret rotation enabled ($SECRET_ID)."
  else
    add_failure "FAIL: secret rotation is not enabled (RotationEnabled=$rot) for $SECRET_ID."
  fi
else
  add_detail "INFO: rotation requirement disabled (REQUIRE_ROTATION=false)."
fi

# ---------- Check 3: secret policy wildcard principal (optional) ----------
if [[ "$CHECK_SECRET_POLICY_WILDCARD" == "true" ]]; then
  policy="$(aws secretsmanager get-resource-policy --secret-id "$SECRET_ID" --region "$REGION" \
    --query "ResourcePolicy" --output text 2>/dev/null || echo "")"
  if [[ -z "$policy" || "$policy" == "None" ]]; then
    add_detail "PASS: no resource policy found (OK) or not applicable ($SECRET_ID)."
  else
    if echo "$policy" | grep -q '"Principal":"\*"' ; then
      add_failure "FAIL: secret resource policy allows wildcard Principal=\"*\" ($SECRET_ID)."
    else
      add_detail "PASS: secret resource policy does not show wildcard Principal (basic check) ($SECRET_ID)."
    fi
  fi
else
  add_detail "INFO: secret policy wildcard check disabled (CHECK_SECRET_POLICY_WILDCARD=false)."
fi

# ---------- Check 4: instance has IAM instance profile ----------
profile_arn="$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$REGION" \
  --query "Reservations[0].Instances[0].IamInstanceProfile.Arn" --output text 2>/dev/null || echo "None")"

if [[ "$profile_arn" =~ ^arn:aws:iam:: ]]; then
  add_detail "PASS: instance has IAM instance profile attached ($INSTANCE_ID)."
else
  add_failure "FAIL: instance has NO IAM instance profile attached ($INSTANCE_ID)."
fi

# ---------- Check 5: resolve profile -> role ----------
resolved_role=""

if [[ "$profile_arn" =~ ^arn:aws:iam:: ]]; then
  profile_name="$(echo "$profile_arn" | awk -F/ '{print $NF}')"

  resolved_role="$(aws iam get-instance-profile --instance-profile-name "$profile_name" \
    --query "InstanceProfile.Roles[0].RoleName" --output text 2>/dev/null || echo "")"

  if [[ -n "$resolved_role" && "$resolved_role" != "None" ]]; then
    add_detail "PASS: resolved instance profile -> role ($profile_name -> $resolved_role)."
  else
    add_failure "FAIL: could not resolve role name from instance profile ($profile_name)."
  fi
fi

# ---------- Check 6: expected role match (if EXPECTED_ROLE_NAME provided) ----------
if [[ -n "$EXPECTED_ROLE_NAME" ]]; then
  if [[ -n "$resolved_role" && "$resolved_role" == "$EXPECTED_ROLE_NAME" ]]; then
    add_detail "PASS: resolved role matches EXPECTED_ROLE_NAME ($EXPECTED_ROLE_NAME)."
  else
    add_failure "FAIL: resolved role ($resolved_role) does not match EXPECTED_ROLE_NAME ($EXPECTED_ROLE_NAME)."
  fi
else
  EXPECTED_ROLE_NAME="$resolved_role"
  if [[ -n "$EXPECTED_ROLE_NAME" ]]; then
    add_detail "INFO: EXPECTED_ROLE_NAME not set; using resolved role ($EXPECTED_ROLE_NAME)."
  fi
fi

# ---------- Check 7: if run on EC2, verify caller ARN is assumed-role/EXPECTED_ROLE_NAME ----------
caller_arn="$(aws sts get-caller-identity --region "$REGION" --query Arn --output text 2>/dev/null || echo "")"
if [[ -n "$EXPECTED_ROLE_NAME" ]]; then
  if echo "$caller_arn" | grep -q ":assumed-role/$EXPECTED_ROLE_NAME/"; then
    add_detail "PASS: current caller is running as expected role ($EXPECTED_ROLE_NAME)."
    on_instance=true
  else
    add_warning "WARN: current caller ARN is not assumed-role/$EXPECTED_ROLE_NAME (you may be running off-instance)."
    on_instance=false
  fi
else
  add_warning "WARN: expected role unknown; cannot validate caller role context."
  on_instance=false
fi

# ---------- Check 8: on EC2, verify secret describe + (optional) get value ----------
if [[ "${on_instance:-false}" == "true" ]]; then
  if aws secretsmanager describe-secret --secret-id "$SECRET_ID" --region "$REGION" >/dev/null 2>&1; then
    add_detail "PASS: on-instance role can describe secret ($SECRET_ID)."
  else
    add_failure "FAIL: on-instance role cannot describe secret ($SECRET_ID)."
  fi

  if [[ "$CHECK_SECRET_VALUE_READ" == "true" ]]; then
    if aws secretsmanager get-secret-value --secret-id "$SECRET_ID" --region "$REGION" \
        --query "SecretString" --output text >/dev/null 2>&1; then
      add_detail "PASS: on-instance role can read secret value ($SECRET_ID) (value not printed)."
    else
      add_failure "FAIL: on-instance role cannot read secret value ($SECRET_ID)."
    fi
  else
    add_detail "INFO: secret-value read check disabled (CHECK_SECRET_VALUE_READ=false)."
  fi
else
  add_detail "INFO: on-instance checks skipped (not running as expected role on EC2)."
fi

# ---------- Compute result ----------
status="PASS"
exit_code=0

if (( ${#failures[@]} > 0 )); then
  status="FAIL"
  exit_code=2
fi

# ---------- Emit human summary ----------
echo ""
echo "=== SEIR Gate: Secrets + EC2 Role Verification ==="
echo "Timestamp (UTC): $(now_utc)"
echo "Region:          $REGION"
echo "Instance ID:     $INSTANCE_ID"
echo "Secret ID:       $SECRET_ID"
echo "Resolved Role:   ${resolved_role:-"(none)"}"
echo "Caller ARN:      ${caller_arn:-"(unknown)"}"
echo "-----------------------------------------------"

for d in "${details[@]}"; do
  echo "$d"
done

if (( ${#warnings[@]} > 0 )); then
  echo ""
  echo "Warnings:"
  for w in "${warnings[@]}"; do
    echo "  - $w"
  done
fi

if (( ${#failures[@]} > 0 )); then
  echo ""
  echo "Failures:"
  for f in "${failures[@]}"; do
    echo "  - $f"
  done
fi

echo ""
echo "RESULT: $status"
echo "==============================================="
echo ""

# ---------- Ensure output directory and emit JSON ----------
mkdir -p "$(dirname "$OUT_JSON")"

timestamp="$(now_utc)"

jq -n \
  --arg gate "secrets_and_role" \
  --arg ts "$timestamp" \
  --arg region "$REGION" \
  --arg instance_id "$INSTANCE_ID" \
  --arg secret_id "$SECRET_ID" \
  --arg profile_arn "${profile_arn:-}" \
  --arg resolved_role "${resolved_role:-}" \
  --arg caller_arn "${caller_arn:-}" \
  --argjson require_rotation "$REQUIRE_ROTATION" \
  --argjson check_wildcard "$CHECK_SECRET_POLICY_WILDCARD" \
  --argjson check_value_read "$CHECK_SECRET_VALUE_READ" \
  --arg status "$status" \
  --argjson exit_code "$exit_code" \
  --argjson details "$(printf '%s\n' "${details[@]}" | jq -R . | jq -s .)" \
  --argjson warnings "$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)" \
  --argjson failures "$(printf '%s\n' "${failures[@]}" | jq -R . | jq -s .)" \
  '{
    gate: $gate,
    timestamp_utc: $ts,
    region: $region,
    instance_id: $instance_id,
    secret_id: $secret_id,
    resolved_instance_profile_arn: $profile_arn,
    resolved_role_name: $resolved_role,
    caller_arn: $caller_arn,
    toggles: {
      require_rotation: $require_rotation,
      check_secret_policy_wildcard: $check_wildcard,
      check_secret_value_read: $check_value_read
    },
    status: $status,
    exit_code: $exit_code,
    details: $details,
    warnings: $warnings,
    failures: $failures
  }' > "$OUT_JSON"

echo "Wrote: $OUT_JSON"
exit "$exit_code"