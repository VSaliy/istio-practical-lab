#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${REPO_ROOT}/versions.env"

kubectl apply -f "https://raw.githubusercontent.com/metallb/metallb/v${METALLB_VERSION}/config/manifests/metallb-native.yaml"

kubectl wait --for=condition=Established \
  crd/ipaddresspools.metallb.io \
  crd/l2advertisements.metallb.io \
  --timeout=120s

kubectl -n metallb-system rollout status deployment/controller --timeout=180s
kubectl -n metallb-system rollout status daemonset/speaker --timeout=180s

kubectl apply -f "${REPO_ROOT}/kubernetes/metallb/ipaddresspool.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/metallb/l2advertisement.yaml"
