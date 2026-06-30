# Exercise 15: Multi-Tenancy

## Difficulty
Intermediate

## Estimated effort
60-120 minutes

## Learning objectives
- Use namespaces as tenant boundaries.
- Verify cross-namespace service access.
- Apply an Istio authorization policy to block one tenant.

## Prerequisites
- Bookinfo is healthy.
- Authorization policies from other exercises are cleaned up.

## Files used
- `exercises/15-multi-tenancy/manifests/deny-tenant-b-productpage.yaml`

## Environment checks
```bash
kubectl get ns bookinfo --show-labels
kubectl get authorizationpolicy -A
curl -I http://172.22.0.240/productpage
```

## Implementation steps
Create a second tenant namespace:

```bash
kubectl create namespace tenant-b
kubectl label namespace tenant-b istio.io/rev=1-24-2
kubectl run curl -n tenant-b --image=curlimages/curl --restart=Never -- sleep 3600
kubectl wait --for=condition=Ready pod/curl -n tenant-b --timeout=120s
kubectl get pod -n tenant-b
```

Expected: `curl` is `2/2 Running`.

Verify access before policy:

```bash
kubectl exec -n tenant-b curl -c curl -- curl -sS -o /dev/null -w "%{http_code}\n" \
  http://productpage.bookinfo.svc.cluster.local:9080/productpage
```

Expected: `200`.

Apply deny policy:

```bash
kubectl apply -f exercises/15-multi-tenancy/manifests/deny-tenant-b-productpage.yaml
```

Verify denial:

```bash
kubectl exec -n tenant-b curl -c curl -- curl -sS -o /dev/null -w "%{http_code}\n" \
  http://productpage.bookinfo.svc.cluster.local:9080/productpage
```

Expected: `403`.

Verify ingress still works:

```bash
curl -I http://172.22.0.240/productpage
```

Expected: `200 OK`.

## Troubleshooting
If the request still returns `200`, confirm injection and policy attachment:

```bash
kubectl get pod -n tenant-b curl -o jsonpath='{.spec.containers[*].name}{"\n"}'
kubectl get authorizationpolicy deny-tenant-b -n bookinfo -o yaml
kubectl get pod -n bookinfo -l app=productpage --show-labels
istioctl analyze -n bookinfo
```

## Cleanup
```bash
kubectl delete authorizationpolicy deny-tenant-b -n bookinfo --ignore-not-found
kubectl delete namespace tenant-b --ignore-not-found
curl -I http://172.22.0.240/productpage
```

## Architectural lessons
Namespaces are a useful tenancy boundary, but production multi-tenancy also needs ownership, quotas, RBAC, policy, and network segmentation.

## Self-assessment questions
1. Why is namespace isolation not enough by itself?
2. What does `source.namespaces` match?
3. Why should ingress still work after blocking tenant-b?
