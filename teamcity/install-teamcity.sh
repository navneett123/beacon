#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
source "$ROOT/versions.lock"
ARCHIVE="TeamCity-${TEAMCITY_VERSION}.tar.gz"
URL="https://download.jetbrains.com/teamcity/${ARCHIVE}"

java -version 2>&1 | grep -q '21' || { echo 'TeamCity 2026.1 requires Java 21.' >&2; exit 1; }

if ! id teamcity >/dev/null 2>&1; then sudo useradd --system --create-home --home-dir /home/teamcity --shell /bin/bash teamcity; fi
if [[ ! -d /opt/TeamCity ]]; then
  curl -fL "$URL" -o "/tmp/$ARCHIVE"
  sudo tar -xzf "/tmp/$ARCHIVE" -C /opt
  sudo chown -R teamcity:teamcity /opt/TeamCity
fi

# Agent builds Docker images through host Docker socket.
sudo usermod -aG docker teamcity
sudo -u teamcity env JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64 /opt/TeamCity/bin/runAll.sh start

echo 'TeamCity started. UI: http://<VM-IP>:8111'
echo 'Complete first-run setup, then authorize the bundled agent in Agents.'
