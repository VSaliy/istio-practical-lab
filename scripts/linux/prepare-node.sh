#!/usr/bin/env bash
set -euo pipefail

# kubelet and kubeadm in this lab require privileged host changes.
# Exiting early prevents partially applied node state when not running as root.
if [[ "${EUID}" -ne 0 ]]; then
  echo "ERROR: run as root" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${REPO_ROOT}/versions.env"

bash "${REPO_ROOT}/scripts/install/install-containerd.sh"
bash "${REPO_ROOT}/scripts/install/install-kubernetes-packages.sh"

# kubelet requires swap to be disabled for deterministic node admission.
swapoff -a
sed -ri '/\sswap\s/s/^#?/#/' /etc/fstab

# These kernel modules and sysctls are required for bridged pod traffic visibility and forwarding.
cat >/etc/modules-load.d/k8s.conf <<'MOD'
overlay
br_netfilter
MOD
modprobe overlay
modprobe br_netfilter

cat >/etc/sysctl.d/99-kubernetes-cri.conf <<'SYS'
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYS
sysctl --system >/dev/null

echo "Verification:"
lsmod | grep -E 'overlay|br_netfilter' || true
sysctl net.ipv4.ip_forward
crictl info >/dev/null && echo "crictl configured"
