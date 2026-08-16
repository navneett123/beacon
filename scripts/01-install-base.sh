#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../versions.lock"

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg jq git unzip zip openssl openjdk-21-jre-headless

# Docker official repository
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
. /etc/os-release
ARCH=$(dpkg --print-architecture)
echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"

# k3d pinned
curl -fsSL "https://github.com/k3d-io/k3d/releases/download/${K3D_VERSION}/k3d-linux-amd64" -o /tmp/k3d
sudo install -m 0755 /tmp/k3d /usr/local/bin/k3d

# kubectl pinned and checksum-verified
curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
curl -fsSLo /tmp/kubectl.sha256 "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" | sha256sum --check
sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl

printf '\nInstalled versions:\n'
docker --version || true
docker compose version || true
k3d version
kubectl version --client
java -version

echo
echo 'IMPORTANT: log out/in once so Docker group membership is active, then continue with 02-bootstrap-k3d.sh.'
