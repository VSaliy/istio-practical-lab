#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${REPO_ROOT}/versions.env"

kubectl apply -f "https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION:?}/manifests/tigera-operator.yaml"
kubectl wait --for=condition=Established \
  crd/installations.operator.tigera.io \
  crd/apiservers.operator.tigera.io \
  --timeout=120s
kubectl apply -f "${REPO_ROOT}/kubernetes/calico/calico-installation.yaml"
kubectl -n calico-system rollout status ds/calico-node --timeout=180s
