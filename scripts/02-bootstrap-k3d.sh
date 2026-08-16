#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../versions.lock"

command -v docker >/dev/null && docker info >/dev/null
command -v k3d >/dev/null
command -v kubectl >/dev/null

k3d version | grep -q "k3d version ${K3D_VERSION}" || { echo "k3d version mismatch; expected ${K3D_VERSION}" >&2; k3d version >&2; exit 1; }
CLIENT_VERSION=$(kubectl version --client -o json | jq -r .clientVersion.gitVersion)
[[ "$CLIENT_VERSION" == "$KUBECTL_VERSION" ]] || { echo "kubectl mismatch: expected $KUBECTL_VERSION got $CLIENT_VERSION" >&2; exit 1; }

echo "Pulling pinned K3s image: ${K3S_IMAGE}"
docker pull "${K3S_IMAGE}"

if ! k3d registry list 2>/dev/null | awk '{print $1}' | grep -qx 'k3d-beacon-registry'; then
  k3d registry create beacon-registry --port "${REGISTRY_HOST_PORT}"
fi

if ! k3d cluster list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx 'beacon'; then
  k3d cluster create beacon \
    --servers 1 \
    --agents 0 \
    --no-lb \
    --api-port "0.0.0.0:${KUBE_API_PORT}" \
    --image "${K3S_IMAGE}" \
    --registry-use k3d-beacon-registry:5000 \
    --k3s-arg '--disable=traefik@server:0' \
    --k3s-arg '--tls-san=host.docker.internal@server:0' \
    --wait
fi

kubectl create namespace beacon-dev --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace beacon-prod --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "$(dirname "$0")/../kubernetes/bootstrap/octopus-rbac.yaml"

kubectl wait --for=condition=Ready node --all --timeout=120s
kubectl get nodes -o wide
SERVER_VERSION=$(kubectl version -o json | jq -r .serverVersion.gitVersion)
[[ "$SERVER_VERSION" == ${KUBERNETES_VERSION}* ]] || { echo "Kubernetes server mismatch: expected ${KUBERNETES_VERSION}.x, got $SERVER_VERSION" >&2; exit 1; }
echo "[PASS] kubectl=$CLIENT_VERSION Kubernetes=$SERVER_VERSION"
k3d registry list

echo 'K3D BOOTSTRAP: PASS'
