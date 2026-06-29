#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${REPO_ROOT}/versions.env"

if ! command -v istioctl >/dev/null 2>&1; then
  ISTIO_ARCH="${ISTIO_ARCH:-amd64}"
  ISTIO_ARCHIVE="istio-${ISTIO_VERSION}-linux-${ISTIO_ARCH}.tar.gz"
  ISTIO_RELEASE_URL="https://github.com/istio/istio/releases/download/${ISTIO_VERSION}"
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${tmp_dir}"' EXIT

  curl -fsSLo "${tmp_dir}/${ISTIO_ARCHIVE}" "${ISTIO_RELEASE_URL}/${ISTIO_ARCHIVE}"
  curl -fsSLo "${tmp_dir}/${ISTIO_ARCHIVE}.sha256" "${ISTIO_RELEASE_URL}/${ISTIO_ARCHIVE}.sha256"
  (
    cd "${tmp_dir}"
    sha256sum -c "${ISTIO_ARCHIVE}.sha256"
    tar -xzf "${ISTIO_ARCHIVE}"
  )
  sudo install -m 0755 "${tmp_dir}/istio-${ISTIO_VERSION}/bin/istioctl" /usr/local/bin/istioctl
fi

istioctl x precheck
istioctl install -f "${REPO_ROOT}/istio/installation/profiles/lab-profile.yaml" -y
kubectl label namespace default istio.io/rev="${ISTIO_REVISION}" --overwrite
