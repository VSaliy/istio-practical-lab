# Istioctl Installation Path

1. Install pinned `istioctl` version from `versions.env`.
2. Run `istioctl x precheck`.
3. Install with `istio/installation/profiles/lab-profile.yaml`.
4. Label namespaces with `istio.io/rev=<revision>`.
5. Verify with `istioctl proxy-status` and `kubectl get pods -n istio-system`.
