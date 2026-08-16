#!/usr/bin/env bash
set -euo pipefail
SECRET=octopus-deployer-token
NS=beacon-system

for _ in {1..30}; do
  TOKEN_B64=$(kubectl -n "$NS" get secret "$SECRET" -o jsonpath='{.data.token}' 2>/dev/null || true)
  CA_B64=$(kubectl -n "$NS" get secret "$SECRET" -o jsonpath='{.data.ca\.crt}' 2>/dev/null || true)
  [[ -n "$TOKEN_B64" && -n "$CA_B64" ]] && break
  sleep 1
done

[[ -n "${TOKEN_B64:-}" ]] || { echo 'Service-account token was not populated.' >&2; exit 1; }
[[ -n "${CA_B64:-}" ]] || { echo 'Cluster CA was not populated.' >&2; exit 1; }

TOKEN=$(printf '%s' "$TOKEN_B64" | base64 --decode)
CA=$(printf '%s' "$CA_B64" | base64 --decode)
printf 'Kubernetes URL for Octopus: https://host.docker.internal:6550\n'
printf 'Token (store as Octopus Token Account):\n%s\n\n' "$TOKEN"
printf 'CA certificate (save/upload as ca.pem if not using Skip TLS):\n%s\n' "$CA"
