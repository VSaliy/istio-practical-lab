# Metrics Server

Metrics Server provides CPU and memory usage for `kubectl top`.

## Install

```bash
bash scripts/install/install-metrics-server.sh
```

The Hyper-V lab uses kubelet serving certificates that may not be trusted by Metrics Server. The install script patches Metrics Server with:

```text
--kubelet-insecure-tls
--kubelet-preferred-address-types=InternalIP,Hostname
```

## Verification

```bash
kubectl -n kube-system rollout status deployment/metrics-server --timeout=180s
kubectl wait --for=condition=Available apiservice/v1beta1.metrics.k8s.io --timeout=180s
kubectl top nodes
kubectl top pods -A
```

Expected:

- Metrics Server deployment is available
- `v1beta1.metrics.k8s.io` APIService is available
- `kubectl top nodes` returns CPU and memory values

## Manual Patch

If needed, patch the deployment directly:

```bash
kubectl -n kube-system patch deployment metrics-server --type='json' -p='[
  {
    "op": "replace",
    "path": "/spec/template/spec/containers/0/args",
    "value": [
      "--cert-dir=/tmp",
      "--secure-port=10250",
      "--kubelet-preferred-address-types=InternalIP,Hostname",
      "--kubelet-use-node-status-port",
      "--metric-resolution=15s",
      "--kubelet-insecure-tls"
    ]
  }
]'
```

Then:

```bash
kubectl -n kube-system rollout status deployment/metrics-server --timeout=180s
```

## Troubleshooting

```bash
kubectl describe apiservice v1beta1.metrics.k8s.io
kubectl logs -n kube-system deploy/metrics-server --tail=100
```
