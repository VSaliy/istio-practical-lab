# Troubleshooting

Use `scripts/diagnostics/*` collectors first, then inspect:

- `kubectl get events -A --sort-by=.lastTimestamp`
- `istioctl proxy-status`
- `kubectl -n istio-system logs deploy/istiod`
