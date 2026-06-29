#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

kubectl apply -f "${REPO_ROOT}/kubernetes/calico/calico-operator.yaml"
kubectl apply -f "${REPO_ROOT}/kubernetes/calico/calico-installation.yaml"
kubectl -n calico-system rollout status ds/calico-node --timeout=180s
