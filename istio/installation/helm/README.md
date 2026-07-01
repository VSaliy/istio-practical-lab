# Helm Installation Path

The primary lab path uses `istioctl`. Helm is documented here as an alternative installation method for comparison.

Use Helm only on a clean lab cluster or when you explicitly intend Helm to own the Istio release.

## Add repository

```bash
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
```

## Install base, control plane, and gateway

```bash
kubectl create namespace istio-system
helm install istio-base istio/base -n istio-system --set defaultRevision=1-29-5
helm install istiod istio/istiod -n istio-system --set revision=1-29-5
helm install istio-ingressgateway istio/gateway -n istio-system
```

## Verify

```bash
helm list -n istio-system
kubectl get pods -n istio-system
istioctl analyze -A
```

## Cleanup

```bash
helm uninstall istio-ingressgateway -n istio-system
helm uninstall istiod -n istio-system
helm uninstall istio-base -n istio-system
```

Do not mix Helm and `istioctl` ownership for the same Istio resources in the same lab run.
