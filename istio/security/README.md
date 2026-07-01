# Security

This layer contains mTLS and authorization examples for Bookinfo.

## Files

- `manifests/bookinfo-strict-mtls.yaml`
- `manifests/deny-tenant-b-productpage.yaml`
- `manifests/deny-productpage-all.yaml`

## Strict mTLS

```bash
kubectl apply -f istio/security/manifests/bookinfo-strict-mtls.yaml
istioctl analyze -n bookinfo
curl -I http://172.22.0.240/productpage
```

Expected: mesh-injected traffic continues to work.

## Authorization deny test

Create a mesh-injected test namespace and pod:

```bash
kubectl create namespace tenant-b
kubectl label namespace tenant-b istio.io/rev=1-29-5
kubectl run curl -n tenant-b --image=curlimages/curl --restart=Never -- sleep 3600
kubectl wait --for=condition=Ready pod/curl -n tenant-b --timeout=120s
```

Apply a namespace-based deny policy:

```bash
kubectl apply -f istio/security/manifests/deny-tenant-b-productpage.yaml
kubectl exec -n tenant-b curl -c curl -- curl -sS -o /dev/null -w "%{http_code}\n" http://productpage.bookinfo.svc.cluster.local:9080/productpage
```

Expected: `403`.

## Cleanup

```bash
kubectl delete authorizationpolicy deny-tenant-b-productpage deny-productpage-all -n bookinfo --ignore-not-found
kubectl delete peerauthentication bookinfo-strict-mtls -n bookinfo --ignore-not-found
kubectl delete namespace tenant-b --ignore-not-found
curl -I http://172.22.0.240/productpage
```
