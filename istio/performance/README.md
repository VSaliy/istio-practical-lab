# Performance

This layer contains lightweight performance support material. The guided exercise is `exercises/19-performance`.

## Files

- `manifests/bookinfo-load-job.yaml`

## Run in-cluster load

```bash
kubectl apply -f istio/performance/manifests/bookinfo-load-job.yaml
kubectl wait --for=condition=Complete job/bookinfo-load -n bookinfo --timeout=180s
kubectl logs job/bookinfo-load -n bookinfo
```

Watch metrics:

```bash
watch -n 2 'kubectl top nodes && echo && kubectl top pods -n bookinfo && echo && kubectl top pods -n istio-system'
```

## Cleanup

```bash
kubectl delete job bookinfo-load -n bookinfo --ignore-not-found
```
