#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$DIR/.." && pwd)
source "$ROOT/versions.lock"
ENV_FILE="$DIR/.env"
if [[ -f "$ENV_FILE" ]]; then
  echo "$ENV_FILE already exists; leaving it unchanged."
  exit 0
fi
SA="Bcn!$(openssl rand -hex 12)Aa1"
ADMIN="Bcn!$(openssl rand -hex 10)Zz9"
MASTER=$(openssl rand 16 | base64)
cat > "$ENV_FILE" <<EOF2
OCTOPUS_VERSION=$OCTOPUS_VERSION
KUBECTL_VERSION=$KUBECTL_VERSION
MSSQL_IMAGE=$MSSQL_IMAGE
MSSQL_SA_PASSWORD=$SA
OCTOPUS_ADMIN_USERNAME=admin
OCTOPUS_ADMIN_PASSWORD=$ADMIN
OCTOPUS_ADMIN_EMAIL=admin@beacon.local
OCTOPUS_MASTER_KEY=$MASTER
OCTOPUS_SERVER_BASE64_LICENSE=
EOF2
chmod 600 "$ENV_FILE"
echo "Created $ENV_FILE"
echo "Octopus login: admin"
echo "Octopus password: $ADMIN"
echo 'Keep octopus/.env private; it is excluded by .gitignore.'
