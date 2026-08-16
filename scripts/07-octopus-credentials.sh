#!/usr/bin/env bash
set -euo pipefail

NS="beacon-system"
SA="octopus-deployer"
TOKEN_DURATION="${TOKEN_DURATION:-8760h}"
CA_FILE="${HOME}/beacon-k3d-ca.pem"

echo "Checking Octopus service account..."
kubectl -n "$NS" get serviceaccount "$SA" >/dev/null

echo "Generating Kubernetes service-account token..."
TOKEN="$(kubectl -n "$NS" create token "$SA" --duration="$TOKEN_DURATION")"

[[ -n "$TOKEN" ]] || {
  echo "ERROR: Failed to generate service-account token." >&2
  exit 1
}

echo "Verifying RBAC access..."

DEV_ACCESS="$(
  kubectl --token="$TOKEN" auth can-i get pods -n beacon-dev
)"

PROD_ACCESS="$(
  kubectl --token="$TOKEN" auth can-i get pods -n beacon-prod
)"

[[ "$DEV_ACCESS" == "yes" ]] || {
  echo "ERROR: Token cannot access beacon-dev." >&2
  exit 1
}

[[ "$PROD_ACCESS" == "yes" ]] || {
  echo "ERROR: Token cannot access beacon-prod." >&2
  exit 1
}

echo "[PASS] Token can access beacon-dev"
echo "[PASS] Token can access beacon-prod"

echo "Extracting Kubernetes cluster CA..."

CA_B64="$(
  kubectl config view \
    --raw \
    --minify \
    -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'
)"

if [[ -n "$CA_B64" ]]; then
  printf '%s' "$CA_B64" | base64 --decode > "$CA_FILE"
else
  CA_PATH="$(
    kubectl config view \
      --raw \
      --minify \
      -o jsonpath='{.clusters[0].cluster.certificate-authority}'
  )"

  [[ -n "$CA_PATH" && -f "$CA_PATH" ]] || {
    echo "ERROR: Kubernetes CA certificate could not be located." >&2
    exit 1
  }

  cp "$CA_PATH" "$CA_FILE"
fi

chmod 600 "$CA_FILE"

echo
echo "=================================================="
echo "OCTOPUS KUBERNETES CONNECTION DETAILS"
echo "=================================================="
echo
echo "Kubernetes URL:"
echo "https://host.docker.internal:6550"
echo
echo "Token:"
echo "$TOKEN"
echo
echo "CA certificate file:"
echo "$CA_FILE"
echo
echo "=================================================="
echo "OCTOPUS CREDENTIAL GENERATION: PASS"
echo "=================================================="
