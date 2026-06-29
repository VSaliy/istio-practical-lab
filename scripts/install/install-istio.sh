#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${REPO_ROOT}/versions.env"

if ! command -v istioctl >/dev/null 2>&1; then
  curl -fsSL https://istio.io/downloadIstio | ISTIO_VERSION="${ISTIO_VERSION}" sh -
  sudo install -m 0755 "istio-${ISTIO_VERSION}/bin/istioctl" /usr/local/bin/istioctl
fi

istioctl x precheck
istioctl install -f "${REPO_ROOT}/istio/installation/profiles/lab-profile.yaml" -y
kubectl label namespace default istio.io/rev="${ISTIO_REVISION}" --overwrite
