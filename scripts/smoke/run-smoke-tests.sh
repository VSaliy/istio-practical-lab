#!/usr/bin/env bash
set -euo pipefail

echo "[smoke] nodes"
kubectl get nodes -o wide

echo "[smoke] core pods"
kubectl get pods -A

echo "[smoke] istio analyze"
istioctl analyze

echo "[smoke] bookinfo"
kubectl -n bookinfo get pods,svc
