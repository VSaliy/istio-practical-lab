#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${REPO_ROOT}/versions.env"

kubectl apply -f "https://github.com/kubernetes-sigs/metrics-server/releases/download/v${METRICS_SERVER_VERSION:?}/components.yaml"
kubectl -n kube-system set args deployment/metrics-server --containers=metrics-server -- \
  --cert-dir=/tmp \
  --secure-port=10250 \
  --kubelet-preferred-address-types=InternalIP,Hostname \
  --kubelet-use-node-status-port \
  --metric-resolution=15s \
  --kubelet-insecure-tls
kubectl -n kube-system rollout status deployment/metrics-server --timeout=180s
kubectl wait --for=condition=Available apiservice/v1beta1.metrics.k8s.io --timeout=180s
