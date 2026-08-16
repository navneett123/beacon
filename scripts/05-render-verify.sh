#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
VERSION=${1:?Usage: 05-render-verify.sh <version>}
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/kubernetes"
cp -R "$ROOT/kubernetes/base" "$TMP/kubernetes/base"
cp -R "$ROOT/kubernetes/overlays" "$TMP/kubernetes/overlays"

# Simulate Octopus variable substitution locally so the exact Kustomize
# configuration can be validated before Octopus is introduced.
find "$TMP/kubernetes/overlays" -type f -name '*.yaml' -print0 | \
  xargs -0 sed -i "s/#{Octopus.Release.Number}/$VERSION/g"

for env in dev prod; do
  echo "Rendering $env overlay for version $VERSION..."
  kubectl kustomize "$TMP/kubernetes/overlays/$env" > "$TMP/$env.yaml"
  grep -q "k3d-beacon-registry:5000/loan-product-service:$VERSION" "$TMP/$env.yaml"
  grep -q "k3d-beacon-registry:5000/eligibility-service:$VERSION" "$TMP/$env.yaml"
  grep -q "APP_VERSION: $VERSION" "$TMP/$env.yaml"
  echo "[PASS] $env Kustomize render"
done
