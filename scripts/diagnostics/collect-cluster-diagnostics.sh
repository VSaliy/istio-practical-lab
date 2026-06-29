#!/usr/bin/env bash
set -euo pipefail

timestamp="$(date +%Y%m%d-%H%M%S)"
out_dir="${OUT_DIR:-diagnostics/${timestamp}}"

mkdir -p "${out_dir}"

run_capture() {
  local name="$1"
  shift

  echo "[diagnostics] ${name}"
  if ! "$@" >"${out_dir}/${name}.txt" 2>&1; then
    echo "[diagnostics] ${name} failed; see ${out_dir}/${name}.txt" >&2
  fi
}

run_capture cluster-version kubectl version
run_capture cluster-info kubectl cluster-info
run_capture nodes kubectl get nodes -o wide
run_capture namespaces kubectl get namespaces
run_capture pods kubectl get pods -A -o wide
run_capture services kubectl get services -A -o wide
run_capture events kubectl get events -A --sort-by=.lastTimestamp
run_capture component-status kubectl get componentstatuses

if command -v istioctl >/dev/null 2>&1; then
  echo "[diagnostics] istio-analyze"
  istioctl analyze -A >"${out_dir}/istio-analyze.txt" 2>&1 || true
fi

echo "Diagnostics written to ${out_dir}"
