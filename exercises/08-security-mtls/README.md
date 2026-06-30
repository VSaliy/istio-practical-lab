# Exercise 08: Security and mTLS

## Difficulty
Intermediate

## Estimated effort
60-120 minutes

## Learning objectives
- Inspect Istio workload certificates.
- Enforce strict mTLS in the Bookinfo namespace.
- Prove non-mesh clients are rejected.

## Prerequisites
- Bookinfo pods are injected and healthy.
- `istioctl` is available.

## Files used
- `exercises/08-security-mtls/manifests/bookinfo-strict-mtls.yaml`

## Environment checks
```bash
kubectl get ns bookinfo --show-labels
kubectl get pods -n bookinfo
```

## Implementation steps
Inspect a proxy secret:

```bash
POD=$(kubectl get pod -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}')
istioctl proxy-config secret "$POD.bookinfo"
```

Apply strict mTLS:

```bash
kubectl apply -f exercises/08-security-mtls/manifests/bookinfo-strict-mtls.yaml
kubectl get peerauthentication -n bookinfo
```

Create a non-injected test client:

```bash
kubectl create namespace mtls-test
kubectl run curl -n mtls-test --image=curlimages/curl --restart=Never -- sleep 3600
kubectl wait --for=condition=Ready pod/curl -n mtls-test --timeout=120s
```

Test from the non-mesh client:

```bash
kubectl exec -n mtls-test curl -- curl -sS -o /dev/null -w "%{http_code}\n" \
  http://productpage.bookinfo.svc.cluster.local:9080/productpage
```

Expected: `000`, connection reset, or TLS-related failure.

Verify ingress still works:

```bash
curl -I http://172.22.0.240/productpage
```

Expected: `200 OK`.

## Verification
```bash
kubectl get peerauthentication -n bookinfo
istioctl analyze -n bookinfo
```

## Cleanup
```bash
kubectl delete namespace mtls-test --ignore-not-found
kubectl delete peerauthentication bookinfo-strict-mtls -n bookinfo --ignore-not-found
curl -I http://172.22.0.240/productpage
```

## Architectural lessons
Strict mTLS requires mesh identity. Non-injected clients do not have Istio certificates and cannot connect to strict workloads.

## Self-assessment questions
1. Why does a non-injected client fail under strict mTLS?
2. Which Istio resource enforces mTLS mode?
3. Why can ingress still work while a plain pod fails?
