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

kubectl -n "$NAMESPACE" rollout status deployment/loan-product-service --timeout=120s
kubectl -n "$NAMESPACE" rollout status deployment/eligibility-service --timeout=120s

echo "Starting port-forward on localhost:${PORT}..."

kubectl -n "$NAMESPACE" port-forward \
  service/eligibility-service \
  "${PORT}:8080" \
  >/tmp/beacon-port-forward.log 2>&1 &

PF_PID=$!

echo "Waiting for eligibility-service to become reachable..."

READY=false

for _ in {1..20}; do
  if curl -fsS \
    "http://127.0.0.1:${PORT}/health" \
    >/dev/null 2>&1; then

    READY=true
    break
  fi

  sleep 1
done

if [[ "$READY" != "true" ]]; then
  echo "ERROR: eligibility-service did not become reachable." >&2
  echo "Port-forward log:" >&2
  cat /tmp/beacon-port-forward.log >&2 || true
  exit 1
fi

echo "[PASS] Health endpoint reachable"

actual_version=$(
  curl -fsS \
    "http://127.0.0.1:${PORT}/version" |
    jq -r '.version'
)

if [[ "$actual_version" != "$VERSION" ]]; then
  echo "ERROR: Expected version $VERSION, got $actual_version" >&2
  exit 1
fi

echo "[PASS] Version verified: $actual_version"

result=$(
  curl -fsS \
    -X POST \
    "http://127.0.0.1:${PORT}/eligibility" \
    -H 'Content-Type: application/json' \
    -d '{
      "product_code": "PL-FLEX",
      "requested_amount": 150000,
      "credit_score": 720,
      "employment_type": "SALARIED",
      "monthly_income": 55000
    }'
)

eligible=$(jq -r '.eligible' <<<"$result")

if [[ "$eligible" != "true" ]]; then
  echo "ERROR: Business eligibility smoke test failed." >&2
  echo "$result" | jq .
  exit 1
fi

echo "[PASS] Business eligibility test"
echo
echo "SMOKE TEST PASS: namespace=$NAMESPACE version=$VERSION"