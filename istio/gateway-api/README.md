# Gateway API

This layer shows the Kubernetes Gateway API equivalent of the Bookinfo ingress route.

## Files

- `manifests/bookinfo-gateway-api.yaml`

## Prerequisites

Gateway API CRDs must be installed before applying these resources:

```bash
kubectl get crd gateways.gateway.networking.k8s.io
kubectl get gatewayclass
```

## Apply

```bash
kubectl apply -f istio/gateway-api/manifests/bookinfo-gateway-api.yaml
kubectl get gateway,httproute -n bookinfo
```

## Verify

Find the gateway address:

```bash
kubectl get gateway bookinfo-gateway-api -n bookinfo
```

Then test the address shown by the Gateway API implementation.

## Cleanup

```bash
kubectl delete -f istio/gateway-api/manifests/bookinfo-gateway-api.yaml --ignore-not-found
```

Classic Istio `Gateway` resources under `istio/gateways` remain the primary lab ingress path.
