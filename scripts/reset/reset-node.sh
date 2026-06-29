#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" != "--confirm-reset" ]]; then
  echo "Refusing reset without --confirm-reset" >&2
  exit 1
fi

echo "WARNING: This will remove kubeadm state, CNI config, and iptables chains."
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d
sudo iptables -F
sudo iptables -t nat -F
