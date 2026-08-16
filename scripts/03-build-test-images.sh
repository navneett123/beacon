#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
VERSION=${1:-0.1.0-preflight}
REGISTRY_PUSH=localhost:5111

python3 -m unittest discover -s "$ROOT/services/loan-product-service/tests" -v
python3 -m unittest discover -s "$ROOT/services/eligibility-service/tests" -v
python3 -m py_compile "$ROOT/services/loan-product-service/app.py" "$ROOT/services/eligibility-service/app.py"

docker build -t "$REGISTRY_PUSH/loan-product-service:$VERSION" "$ROOT/services/loan-product-service"
docker build -t "$REGISTRY_PUSH/eligibility-service:$VERSION" "$ROOT/services/eligibility-service"
docker push "$REGISTRY_PUSH/loan-product-service:$VERSION"
docker push "$REGISTRY_PUSH/eligibility-service:$VERSION"

echo "IMAGE BUILD/PUSH: PASS ($VERSION)"
