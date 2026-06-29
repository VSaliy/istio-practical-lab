#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "ERROR: run as root" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
# shellcheck source=/dev/null
source "${REPO_ROOT}/versions.env"

apt-get update
apt-get install -y apt-transport-https ca-certificates curl gpg

install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION%.*}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBERNETES_VERSION%.*}/deb/ /" >/etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y "kubelet=${KUBERNETES_VERSION}-1.1" "kubeadm=${KUBERNETES_VERSION}-1.1" "kubectl=${KUBERNETES_VERSION}-1.1"
apt-mark hold kubelet kubeadm kubectl

tmp_archive="/tmp/crictl-v${CRICTL_VERSION}-linux-amd64.tar.gz"
curl -fsSL -o "${tmp_archive}" "https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-amd64.tar.gz"
tar -xzf "${tmp_archive}" -C /usr/local/bin crictl
chmod +x /usr/local/bin/crictl

cat >/etc/crictl.yaml <<'CFG'
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
CFG
