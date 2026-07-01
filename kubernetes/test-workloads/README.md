# Test Workloads

Small workloads for validating DNS, service connectivity, image pulls, and policy behavior.

## Files

- `curl-pod.yaml` - long-running curl pod in namespace `lab-test`
- `nginx-pod.yaml` - simple nginx pod in namespace `lab-test`

## Deploy

```bash
kubectl apply -f kubernetes/test-workloads/curl-pod.yaml
kubectl apply -f kubernetes/test-workloads/nginx-pod.yaml
kubectl get pods -n lab-test
```

## Connectivity Checks

```bash
kubectl exec -n lab-test curl -- curl -sS https://kubernetes.default.svc
kubectl exec -n lab-test curl -- nslookup kubernetes.default.svc
kubectl exec -n lab-test curl -- curl -I http://nginx.lab-test.svc.cluster.local
```

## Cleanup

```bash
kubectl delete namespace lab-test --ignore-not-found
```
