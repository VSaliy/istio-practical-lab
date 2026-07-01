# Multi-tenancy

This layer demonstrates namespace-scoped tenant isolation with Istio authorization.

## Files

- `manifests/deny-tenant-b-productpage.yaml`

## Setup tenant namespace

```bash
kubectl create namespace tenant-b
kubectl label namespace tenant-b istio.io/rev=1-29-5
kubectl run curl -n tenant-b --image=curlimages/curl --restart=Never -- sleep 3600
kubectl wait --for=condition=Ready pod/curl -n tenant-b --timeout=120s
```

Baseline:

```bash
kubectl exec -n tenant-b curl -c curl -- curl -sS -o /dev/null -w "%{http_code}\n" http://productpage.bookinfo.svc.cluster.local:9080/productpage
```

Expected: `200`.

Apply deny policy:

```bash
kubectl apply -f istio/multi-tenancy/manifests/deny-tenant-b-productpage.yaml
kubectl exec -n tenant-b curl -c curl -- curl -sS -o /dev/null -w "%{http_code}\n" http://productpage.bookinfo.svc.cluster.local:9080/productpage
```

Expected: `403`.

## Cleanup

```bash
kubectl delete -f istio/multi-tenancy/manifests/deny-tenant-b-productpage.yaml --ignore-not-found
kubectl delete namespace tenant-b --ignore-not-found
```
