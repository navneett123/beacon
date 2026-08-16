#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
MODE=${1:-runtime}

case "$MODE" in
  app)
    kubectl delete namespace beacon-dev beacon-prod --ignore-not-found=true || true
    ;;
  runtime)
    k3d cluster delete beacon || true
    k3d registry delete beacon-registry || true
    rm -rf "$ROOT/.release"
    ;;
  octopus)
    docker compose --env-file "$ROOT/octopus/.env" -f "$ROOT/octopus/docker-compose.yml" down -v --remove-orphans || true
    ;;
  all)
    docker compose --env-file "$ROOT/octopus/.env" -f "$ROOT/octopus/docker-compose.yml" down -v --remove-orphans || true
    k3d cluster delete beacon || true
    k3d registry delete beacon-registry || true
    rm -rf "$ROOT/.release"
    ;;
  *) echo "usage: $0 {app|runtime|octopus|all}" >&2; exit 2;;
esac

echo "Cleanup complete: $MODE (source code preserved)"
