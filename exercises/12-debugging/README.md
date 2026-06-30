# Exercise 12: Debugging

## Difficulty
Intermediate

## Estimated effort
60-120 minutes

## Learning objectives
- Collect repeatable cluster diagnostics.
- Debug Bookinfo from Kubernetes and Istio perspectives.
- Separate pod health, service discovery, and mesh routing failures.

## Prerequisites
- Bookinfo and Istio installed.
- `kubectl` and `istioctl` work on `k8s-control-01`.

## Files used
- `scripts/diagnostics/collect-cluster-diagnostics.sh`
- `docs/troubleshooting.md`

## Environment checks
```bash
kubectl get nodes
kubectl get pods -A
istioctl proxy-status
```

## Implementation steps
Collect diagnostics:

```bash
bash scripts/diagnostics/collect-cluster-diagnostics.sh
ls diagnostics
```

Inspect productpage:

```bash
POD=$(kubectl get pod -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod "$POD" -n bookinfo
kubectl logs "$POD" -n bookinfo -c productpage --tail=50
kubectl logs "$POD" -n bookinfo -c istio-proxy --tail=50
```

Inspect proxy configuration:

```bash
istioctl proxy-config listeners "$POD.bookinfo"
istioctl proxy-config routes "$POD.bookinfo"
istioctl proxy-config clusters "$POD.bookinfo" | grep bookinfo
istioctl proxy-config endpoints "$POD.bookinfo" | grep bookinfo
```

## Failure experiment
Break the Bookinfo `VirtualService`, observe the failure, then restore:

```bash
kubectl delete virtualservice bookinfo -n bookinfo
curl -I http://172.22.0.240/productpage
istioctl analyze -n bookinfo
kubectl apply -n bookinfo -f /tmp/istio-1.24.2/samples/bookinfo/networking/bookinfo-gateway.yaml
curl -I http://172.22.0.240/productpage
```

## Verification
```bash
curl -I http://172.22.0.240/productpage
istioctl proxy-status
istioctl analyze -A
```

## Cleanup
Diagnostics directories can be kept for analysis. Remove them only when no longer needed:

```bash
ls diagnostics
```

## Architectural lessons
Debugging Istio requires checking both the Kubernetes object model and the generated Envoy configuration.

## Self-assessment questions
1. Which command shows whether proxies are synced?
2. Which logs show application behavior versus mesh proxy behavior?
3. Why should diagnostics be collected before making fixes?
