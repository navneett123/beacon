#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
VERSION=${1:-${BUILD_NUMBER:+1.0.${BUILD_NUMBER}}}
VERSION=${VERSION:-1.0.local}

"$ROOT/scripts/03-build-test-images.sh" "$VERSION"
"$ROOT/scripts/05-render-verify.sh" "$VERSION"

echo "##teamcity[setParameter name='env.BEACON_VERSION' value='$VERSION']"
echo "Beacon CI complete: $VERSION"
echo "Images pushed:"
echo "  localhost:5111/loan-product-service:$VERSION"
echo "  localhost:5111/eligibility-service:$VERSION"
echo "Create Octopus release with the SAME release number: $VERSION"
