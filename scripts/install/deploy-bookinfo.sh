#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${REPO_ROOT}/versions.env"

if ! command -v istioctl >/dev/null 2>&1; then
  echo "istioctl is required" >&2
  exit 1
fi

ISTIO_TMP_DIR="/tmp/istio-${ISTIO_VERSION}"
if [[ ! -d "${ISTIO_TMP_DIR}/samples/bookinfo" ]]; then
  mkdir -p /tmp
  curl -fsSL https://istio.io/downloadIstio | ISTIO_VERSION="${ISTIO_VERSION}" TARGET_ARCH=x86_64 sh -
  mv "istio-${ISTIO_VERSION}" "${ISTIO_TMP_DIR}"
fi

kubectl create namespace bookinfo --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace bookinfo istio.io/rev="${ISTIO_REVISION}" --overwrite
kubectl apply -n bookinfo -f "${ISTIO_TMP_DIR}/samples/bookinfo/platform/kube/bookinfo.yaml"
kubectl apply -n bookinfo -f "${ISTIO_TMP_DIR}/samples/bookinfo/networking/bookinfo-gateway.yaml"
