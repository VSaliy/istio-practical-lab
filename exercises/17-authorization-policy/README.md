# Exercise 17: Istio AuthorizationPolicy

## Difficulty
Intermediate

## Estimated effort
60-120 minutes

## Learning objectives
- Distinguish Istio `AuthorizationPolicy` from Kubernetes `NetworkPolicy`.
- Use mesh identity and namespace context to authorize service-to-service traffic.
- Verify deny behavior with HTTP status codes instead of network timeouts.
- Keep ingress access working while blocking a specific internal test client.

## Architectural context
This exercise builds on Bookinfo running in the `bookinfo` namespace with Istio sidecar injection enabled.

Kubernetes `NetworkPolicy` works at L3/L4 and commonly fails as a timeout. Istio `AuthorizationPolicy` is evaluated by the mesh data plane and commonly fails as HTTP `403` when the request reaches an Envoy proxy but is denied by policy.

## Prerequisites
- Exercises 01-16 completed.
- All nodes are `Ready`.
- Bookinfo pods are `2/2 Running`.
- Istio ingress gateway is reachable at `172.22.0.240`.
- No leftover broad deny policies from previous security experiments.

## Files used
- `exercises/17-authorization-policy/manifests/deny-authz-test-namespace.yaml`
- `exercises/17-authorization-policy/manifests/deny-productpage-all.yaml`

## Baseline checks
Run these on `k8s-control-01` from the repository root:

```bash
kubectl get pods -n bookinfo
kubectl get authorizationpolicy -A
curl -I http://172.22.0.240/productpage
```

Expected:
- Bookinfo pods are `2/2 Running`.
- No broad deny policy is active.
- Ingress returns `HTTP/1.1 200 OK`.

If a policy from a previous attempt remains, remove it first:

```bash
kubectl delete authorizationpolicy deny-productpage-all -n bookinfo --ignore-not-found
kubectl delete authorizationpolicy deny-authz-test -n bookinfo --ignore-not-found
```

## Create a mesh-injected test client
Create a separate namespace and a curl pod that has an Istio sidecar:

```bash
kubectl create namespace authz-test
kubectl label namespace authz-test istio.io/rev=1-24-2
kubectl run curl -n authz-test --image=curlimages/curl --restart=Never -- sleep 3600
kubectl wait --for=condition=Ready pod/curl -n authz-test --timeout=120s
kubectl get pod -n authz-test
```

Expected:

```text
curl   2/2   Running
```

Confirm the injected containers:

```bash
kubectl get pod -n authz-test curl -o jsonpath='{.spec.containers[*].name}{"\n"}'
```

Expected:

```text
curl istio-proxy
```

## Verify allowed traffic
Before applying authorization policy, the test client should reach Bookinfo:

```bash
kubectl exec -n authz-test curl -c curl -- curl -sS -o /dev/null -w "%{http_code}\n" \
  http://productpage.bookinfo.svc.cluster.local:9080/productpage
```

Expected:

```text
200
```

## Deny traffic from the test namespace
Apply a policy that denies requests from `authz-test` to the `productpage` workload:

```bash
kubectl apply -f exercises/17-authorization-policy/manifests/deny-authz-test-namespace.yaml
```

Verify the policy:

```bash
kubectl get authorizationpolicy deny-authz-test -n bookinfo -o yaml
istioctl analyze -n bookinfo
```

Test again:

```bash
kubectl exec -n authz-test curl -c curl -- curl -sS -o /dev/null -w "%{http_code}\n" \
  http://productpage.bookinfo.svc.cluster.local:9080/productpage
```

Expected:

```text
403
```

This is the important difference from the NetworkPolicy exercise: the request is rejected by Istio authorization, not dropped by the network.

## Verify ingress still works
The policy denies only the `authz-test` namespace source. It should not block normal ingress gateway traffic:

```bash
curl -I http://172.22.0.240/productpage
```

Expected:

```text
HTTP/1.1 200 OK
```

## Failure experiment: deny all productpage traffic
Use this only to prove the selector attaches to `productpage` correctly:

```bash
kubectl apply -f exercises/17-authorization-policy/manifests/deny-productpage-all.yaml
```

Test:

```bash
kubectl exec -n authz-test curl -c curl -- curl -sS -o /dev/null -w "%{http_code}\n" \
  http://productpage.bookinfo.svc.cluster.local:9080/productpage
```

Expected:

```text
403
```

Clean up the broad deny immediately:

```bash
kubectl delete authorizationpolicy deny-productpage-all -n bookinfo
```

## Troubleshooting
If the deny policy returns `200`, check these in order:

```bash
kubectl get pod -n authz-test curl -o jsonpath='{.spec.containers[*].name}{"\n"}'
kubectl get ns authz-test --show-labels
kubectl get pod -n bookinfo -l app=productpage --show-labels
kubectl get authorizationpolicy deny-authz-test -n bookinfo -o yaml
istioctl analyze -n bookinfo
```

Expected signals:
- `authz-test/curl` includes `istio-proxy`.
- `authz-test` has `istio.io/rev=1-24-2`.
- `productpage` pods have `app=productpage`.
- `deny-productpage-all` returns `403` when applied.

If a `source.principals` policy does not match, prefer `source.namespaces` for this lab unless you are specifically debugging SPIFFE identity propagation.

## Cleanup
Restore the baseline:

```bash
kubectl delete authorizationpolicy deny-productpage-all -n bookinfo --ignore-not-found
kubectl delete authorizationpolicy deny-authz-test -n bookinfo --ignore-not-found
kubectl delete namespace authz-test --ignore-not-found
curl -I http://172.22.0.240/productpage
```

Expected final result:

```text
HTTP/1.1 200 OK
```

## Architectural lessons
- Use `AuthorizationPolicy` for service identity, namespace, path, method, and workload-level authorization.
- Use `NetworkPolicy` for network segmentation and L3/L4 blast-radius reduction.
- A mesh authorization failure should usually be diagnosable from HTTP status, Envoy config, and Istio analysis.
- A broad deny policy is useful for debugging selectors, but it should be removed immediately after the test.

## Production considerations
- Prefer explicit `ALLOW` policies for sensitive services after validating dependencies.
- Use dedicated service accounts instead of the default service account for production workloads.
- Version policy manifests with application ownership and rollback instructions.
- Test policies in staging with representative callers before applying them to production namespaces.

## Self-assessment questions
1. Why does Istio authorization return `403` while Kubernetes NetworkPolicy often produces a timeout?
2. Which workload labels does the `selector` match in this exercise?
3. Why is `source.namespaces` easier to demonstrate than `source.principals` in this lab?
4. What cleanup is required before moving to the next exercise?
