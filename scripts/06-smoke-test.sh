#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=${1:?usage: $0 <namespace> <expected-version>}
VERSION=${2:?usage: $0 <namespace> <expected-version>}
PORT=${SMOKE_PORT:-18080}

cleanup() {
  [[ -n "${PF_PID:-}" ]] && kill "$PF_PID" 2>/dev/null || true
}

trap cleanup EXIT

echo "Waiting for Beacon deployments..."

kubectl \
  -n "$NAMESPACE" \
  rollout status \
  deployment/loan-product-service \
  --timeout=120s

kubectl \
  -n "$NAMESPACE" \
  rollout status \
  deployment/eligibility-service \
  --timeout=120s

echo "Starting port-forward on localhost:${PORT}..."

kubectl \
  -n "$NAMESPACE" \
  port-forward \
  service/eligibility-service \
  "${PORT}:8080" \
  >/tmp/beacon-port-forward.log \
  2>&1 &

PF_PID=$!

echo "Waiting for eligibility-service to become reachable..."

READY=false

for _ in {1..20}; do
  if curl \
    -fsS \
    "http://127.0.0.1:${PORT}/health" \
    >/dev/null \
    2>&1
  then
    READY=true
    break
  fi

  sleep 1
done

if [[ "$READY" != "true" ]]; then
  echo "ERROR: eligibility-service did not become reachable." >&2
  echo "Port-forward log:" >&2

  cat \
    /tmp/beacon-port-forward.log \
    >&2 \
    || true

  exit 1
fi

echo "[PASS] Health endpoint reachable"


# -------------------------------------------------
# Validate Beacon web UI
# -------------------------------------------------

ui_content=$(
  curl \
    -fsS \
    "http://127.0.0.1:${PORT}/"
)

if ! grep \
  -Fq \
  "Beacon · Loan Eligibility" \
  <<<"$ui_content"
then
  echo "ERROR: Beacon web UI did not render expected content." >&2
  exit 1
fi

echo "[PASS] Web UI reachable"


# -------------------------------------------------
# Validate deployed release version
# -------------------------------------------------

actual_version=$(
  curl \
    -fsS \
    "http://127.0.0.1:${PORT}/version" \
  |
  jq \
    -r \
    '.version'
)

if [[ "$actual_version" != "$VERSION" ]]; then
  echo "ERROR: Expected version $VERSION, got $actual_version" >&2
  exit 1
fi

echo "[PASS] Version verified: $actual_version"


# -------------------------------------------------
# Existing business eligibility smoke test
# -------------------------------------------------

result=$(
  curl \
    -fsS \
    -X POST \
    "http://127.0.0.1:${PORT}/eligibility" \
    -H \
    'Content-Type: application/json' \
    -d \
    '{
      "product_code": "PL-FLEX",
      "requested_amount": 150000,
      "credit_score": 720,
      "employment_type": "SALARIED",
      "monthly_income": 55000
    }'
)

eligible=$(
  jq \
    -r \
    '.eligible' \
    <<<"$result"
)

if [[ "$eligible" != "true" ]]; then
  echo "ERROR: Business eligibility smoke test failed." >&2
  echo "$result" | jq .
  exit 1
fi

echo "[PASS] Business eligibility test"


# -------------------------------------------------
# FEATURE 1:
# Validate Explainable Eligibility checks
# -------------------------------------------------

check_count=$(
  jq \
    -r \
    '.checks | length' \
    <<<"$result"
)

if [[ "$check_count" != "4" ]]; then
  echo "ERROR: Expected 4 explainable policy checks, got $check_count." >&2
  echo "$result" | jq .
  exit 1
fi


failed_checks=$(
  jq \
    -r \
    '[.checks[] | select(.passed != true)] | length' \
    <<<"$result"
)

if [[ "$failed_checks" != "0" ]]; then
  echo "ERROR: Eligible smoke case contains failed policy checks." >&2
  echo "$result" | jq .
  exit 1
fi


required_rules=(
  "requested_amount"
  "credit_score"
  "monthly_income"
  "employment_type"
)

for rule in "${required_rules[@]}"; do

  rule_present=$(
    jq \
      --arg rule "$rule" \
      -r \
      '[.checks[] | select(.rule == $rule)] | length' \
      <<<"$result"
  )

  if [[ "$rule_present" != "1" ]]; then
    echo "ERROR: Explainable policy rule missing or duplicated: $rule" >&2
    echo "$result" | jq .
    exit 1
  fi
done


echo "[PASS] Explainable policy checks verified: 4/4 passed"


# -------------------------------------------------
# Feature UI marker validation
# Ensures updated UI made it into the container.
# -------------------------------------------------

if ! grep \
  -Fq \
  "Policy checks" \
  <<<"$ui_content"
then
  echo "ERROR: Explainable Eligibility UI was not found." >&2
  exit 1
fi

echo "[PASS] Explainable Eligibility UI verified"


echo
echo "SMOKE TEST PASS: namespace=$NAMESPACE version=$VERSION"