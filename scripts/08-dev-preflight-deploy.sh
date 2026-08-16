#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
VERSION=${1:-0.1.0-preflight}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/kubernetes"
cp -R "$ROOT/kubernetes/base" "$TMP/kubernetes/base"
cp -R "$ROOT/kubernetes/overlays" "$TMP/kubernetes/overlays"
find "$TMP/kubernetes/overlays" -type f -name '*.yaml' -print0 | \
  xargs -0 sed -i "s/#{Octopus.Release.Number}/$VERSION/g"

kubectl apply -k "$TMP/kubernetes/overlays/dev"
kubectl -n beacon-dev rollout status deployment/loan-product-service --timeout=120s
kubectl -n beacon-dev rollout status deployment/eligibility-service --timeout=120s
"$ROOT/scripts/06-smoke-test.sh" beacon-dev "$VERSION"
echo "DIRECT DEV PREFLIGHT DEPLOY: PASS ($VERSION)"
