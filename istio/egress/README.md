# Egress

This layer contains a ServiceEntry example for allowing mesh workloads to reach `httpbin.org`.

## Files

- `manifests/httpbin-serviceentry.yaml`

## Test without policy

```bash
kubectl run egress-curl -n bookinfo --image=curlimages/curl --restart=Never -- sleep 3600
kubectl wait --for=condition=Ready pod/egress-curl -n bookinfo --timeout=120s
kubectl exec -n bookinfo egress-curl -c egress-curl -- curl -I https://httpbin.org/status/200
```

If the container name differs, discover it:

```bash
kubectl get pod -n bookinfo egress-curl -o jsonpath='{.spec.containers[*].name}{"\n"}'
```

## Apply ServiceEntry

```bash
kubectl apply -f istio/egress/manifests/httpbin-serviceentry.yaml
istioctl analyze -n bookinfo
```

## Cleanup

```bash
kubectl delete serviceentry httpbin-egress -n bookinfo --ignore-not-found
kubectl delete pod egress-curl -n bookinfo --ignore-not-found
```
