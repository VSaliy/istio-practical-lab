# Gateways

Classic Istio gateway resources for Bookinfo ingress.

## Files

- `manifests/bookinfo-gateway.yaml`
- `manifests/bookinfo-virtualservice.yaml`

## Apply

```bash
kubectl apply -f istio/gateways/manifests/bookinfo-gateway.yaml
kubectl apply -f istio/gateways/manifests/bookinfo-virtualservice.yaml
istioctl analyze -n bookinfo
curl -I http://172.22.0.240/productpage
```

Expected: `HTTP/1.1 200 OK`.

## Verify

```bash
kubectl get gateway,virtualservice -n bookinfo
kubectl get svc istio-ingressgateway -n istio-system
```

## Cleanup

Leave these resources in place if you want Bookinfo ingress to keep working.
