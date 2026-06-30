# Exercise 16: Kubernetes NetworkPolicy and Istio

## Difficulty
Intermediate

## Estimated effort
60-120 minutes

## Learning objectives
- Compare Kubernetes `NetworkPolicy` with Istio `AuthorizationPolicy`.
- Use Calico to block L3/L4 ingress into the Bookinfo namespace.
- Observe timeout behavior from a blocked client.

## Prerequisites
- Calico is installed and enforcing NetworkPolicy.
- Bookinfo is healthy.
- Authorization policies from previous exercises are cleaned up.

## Files used
- `exercises/16-network-policy/manifests/deny-all-bookinfo-ingress.yaml`

## Environment checks
```bash
kubectl get pods -n calico-system
kubectl get pods -n bookinfo
curl -I http://172.22.0.240/productpage
```

## Implementation steps
Create a non-mesh test namespace:

```bash
kubectl create namespace netpol-test
kubectl run curl -n netpol-test --image=curlimages/curl --restart=Never -- sleep 3600
kubectl wait --for=condition=Ready pod/curl -n netpol-test --timeout=120s
```

Verify access before policy:

```bash
kubectl exec -n netpol-test curl -- curl -sS -o /dev/null -w "%{http_code}\n" \
  http://productpage.bookinfo.svc.cluster.local:9080/productpage
```

Expected: `200`.

Apply deny-all ingress to Bookinfo:

```bash
kubectl apply -f exercises/16-network-policy/manifests/deny-all-bookinfo-ingress.yaml
```

Test again:

```bash
kubectl exec -n netpol-test curl -- curl --max-time 5 -sS -o /dev/null -w "%{http_code}\n" \
  http://productpage.bookinfo.svc.cluster.local:9080/productpage
```

Expected: timeout and `000`.

Check ingress:

```bash
curl -I http://172.22.0.240/productpage
```

Depending on endpoint placement and allowed paths, ingress may still work in this lab. The required proof is that the test namespace was blocked by NetworkPolicy.

## Verification
```bash
kubectl get networkpolicy -n bookinfo
kubectl describe networkpolicy deny-all-ingress -n bookinfo
```

## Cleanup
```bash
kubectl delete networkpolicy deny-all-ingress -n bookinfo --ignore-not-found
kubectl delete namespace netpol-test --ignore-not-found
curl -I http://172.22.0.240/productpage
```

Expected final result: `HTTP/1.1 200 OK`.

## Architectural lessons
Kubernetes NetworkPolicy is network-level segmentation. A denied connection commonly times out. Istio AuthorizationPolicy is mesh-level authorization and commonly returns `403`.

## Self-assessment questions
1. Why did the blocked request time out instead of returning `403`?
2. Which CNI plugin enforces this policy?
3. Why should NetworkPolicy and AuthorizationPolicy be used together?
