# Exercise 09: Ingress

## Difficulty
Intermediate

## Estimated effort
45-90 minutes

## Learning objectives
- Trace external traffic through MetalLB and the Istio ingress gateway.
- Inspect `Gateway` and `VirtualService` resources.
- Recover from a broken ingress route.

## Prerequisites
- MetalLB installed with pool `172.22.0.240-172.22.0.250`.
- Istio ingress gateway has external IP `172.22.0.240`.
- Bookinfo is deployed.

## Files used
- `scripts/install/deploy-bookinfo.sh`
- `/tmp/istio-1.24.2/samples/bookinfo/networking/bookinfo-gateway.yaml`
- `kubernetes/metallb/ipaddresspool.yaml`

## Environment checks
```bash
kubectl get svc -n istio-system istio-ingressgateway
kubectl get gateway,virtualservice -n bookinfo
curl -I http://172.22.0.240/productpage
```

## Implementation steps
Inspect the ingress service:

```bash
kubectl describe svc -n istio-system istio-ingressgateway
kubectl get endpoints -n istio-system istio-ingressgateway
```

Inspect Bookinfo routing:

```bash
kubectl get gateway bookinfo-gateway -n bookinfo -o yaml
kubectl get virtualservice bookinfo -n bookinfo -o yaml
```

Test from cluster and host:

```bash
curl -I http://172.22.0.240/productpage
curl -s http://172.22.0.240/productpage | grep -i "Simple Bookstore"
```

## Expected output
- ingress gateway service type is `LoadBalancer`
- external IP is `172.22.0.240`
- `/productpage` returns `200 OK`

## Failure experiment
Delete the `VirtualService` and observe failure:

```bash
kubectl delete virtualservice bookinfo -n bookinfo
curl -I http://172.22.0.240/productpage
```

Restore:

```bash
kubectl apply -n bookinfo -f /tmp/istio-1.24.2/samples/bookinfo/networking/bookinfo-gateway.yaml
curl -I http://172.22.0.240/productpage
```

## Cleanup
No cleanup is required after restore.

## Architectural lessons
MetalLB assigns an external IP to the Kubernetes service. Istio `Gateway` accepts traffic on that gateway, and `VirtualService` routes HTTP paths to internal services.

## Self-assessment questions
1. Which object owns the external IP?
2. Which object matches `/productpage`?
3. Why does deleting the `VirtualService` break ingress while pods remain healthy?
