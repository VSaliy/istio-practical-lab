#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 '<kubeadm join ... command>'" >&2
  exit 1
fi

sudo bash -c "$1"
