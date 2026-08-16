#!/usr/bin/env bash
set -euo pipefail
DIR=$(cd "$(dirname "$0")" && pwd)
[[ -f "$DIR/.env" ]] || { echo 'Run ./octopus/prepare-env.sh first.' >&2; exit 1; }

docker compose --env-file "$DIR/.env" -f "$DIR/docker-compose.yml" config >/dev/null
docker compose --env-file "$DIR/.env" -f "$DIR/docker-compose.yml" pull db
docker compose --env-file "$DIR/.env" -f "$DIR/docker-compose.yml" build --pull octopus
docker compose --env-file "$DIR/.env" -f "$DIR/docker-compose.yml" up -d

for _ in {1..60}; do
  if curl -fsS --max-time 3 http://127.0.0.1:1322/ >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
curl -fsS --max-time 5 http://127.0.0.1:1322/ >/dev/null || {
  echo 'Octopus did not become reachable on http://127.0.0.1:1322' >&2
  docker compose --env-file "$DIR/.env" -f "$DIR/docker-compose.yml" logs --tail=100 octopus db >&2 || true
  exit 1
}

docker compose --env-file "$DIR/.env" -f "$DIR/docker-compose.yml" exec -T octopus kubectl version --client
docker compose --env-file "$DIR/.env" -f "$DIR/docker-compose.yml" ps
echo 'OCTOPUS STARTUP: PASS'
echo 'UI: http://<VM-IP>:1322'
