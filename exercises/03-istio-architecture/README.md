# Exercise 03: Istio Architecture

## Difficulty
Intermediate

## Estimated effort
60-90 minutes

## Learning objectives
- Identify Istio control-plane and data-plane components.
- Map Bookinfo traffic from MetalLB to ingress gateway to sidecars.
- Use `istioctl` to inspect proxy sync state and generated Envoy config.

## Prerequisites
- Exercise 02 complete.
- Istio and Bookinfo installed.
- `istioctl` available on `k8s-control-01`.

## Files used
- `istio/installation/profiles/lab-profile.yaml`
- `scripts/install/install-istio.sh`
- `scripts/install/deploy-bookinfo.sh`
- `docs/architecture.md`

## Environment checks
```bash
kubectl get nodes -o wide
kubectl get pods -n istio-system
kubectl get pods -n bookinfo
kubectl get svc -n istio-system istio-ingressgateway
```

Expected:
- all nodes are `Ready`
- `istiod-1-24-2` is `Running`
- `istio-ingressgateway` is `Running`
- Bookinfo pods are `2/2 Running`

## Implementation steps
1. Inspect the Istio control plane.
2. Inspect injected Bookinfo workloads.
3. Verify ingress path.
4. Compare Kubernetes resources with Istio proxy state.

## Commands
```bash
kubectl get deploy,svc,pods -n istio-system -o wide
kubectl get gateway,virtualservice,destinationrule -n bookinfo
kubectl get pods -n bookinfo -o wide
istioctl proxy-status
istioctl analyze -A
curl -I http://172.22.0.240/productpage
```

Inspect one workload proxy:

```bash
POD=$(kubectl get pod -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config routes "$POD.bookinfo"
istioctl proxy-config clusters "$POD.bookinfo" | grep bookinfo
istioctl proxy-config endpoints "$POD.bookinfo" | grep bookinfo
```

## Expected output
- `istioctl proxy-status` shows Bookinfo and ingress proxies as `SYNCED`.
- `curl -I` returns `HTTP/1.1 200 OK`.
- `istioctl analyze -A` has no blocking errors. Informational namespace and port naming warnings can appear in this lab.

## Verification
```bash
kubectl get pods -n bookinfo
kubectl get svc -n istio-system istio-ingressgateway
istioctl proxy-status
curl -s http://172.22.0.240/productpage | grep -i "Simple Bookstore"
```

## Failure experiment
Delete the Bookinfo `VirtualService`, observe ingress failure, then restore it:

```bash
kubectl delete virtualservice bookinfo -n bookinfo
curl -I http://172.22.0.240/productpage
kubectl apply -n bookinfo -f /tmp/istio-1.24.2/samples/bookinfo/networking/bookinfo-gateway.yaml
curl -I http://172.22.0.240/productpage
```

Expected:
- request fails or returns an error while the `VirtualService` is absent
- request returns `200 OK` after restore

## Cleanup
No cleanup is required if the gateway was restored.

## Architectural lessons
- `istiod` programs Envoy sidecars and gateways through xDS.
- The ingress gateway is a mesh proxy exposed by a Kubernetes `LoadBalancer` service.
- Application pods keep their normal Kubernetes services; Istio adds policy and routing on top.

## Self-assessment questions
1. Which resource exposes Bookinfo outside the cluster?
2. What does `SYNCED` mean in `istioctl proxy-status`?
3. Why can Kubernetes pods be healthy while Istio routing is broken?
