# Exercise 10: Egress

## Difficulty
Intermediate

## Estimated effort
45-90 minutes

## Learning objectives
- Understand how Istio models outbound external services.
- Create a `ServiceEntry` for `httpbin.org`.
- Verify external HTTPS traffic from an injected workload.

## Prerequisites
- Bookinfo namespace is injected.
- Worker nodes have outbound internet access.

## Files used
- `exercises/10-egress/manifests/httpbin-serviceentry.yaml`

## Environment checks
```bash
kubectl get ns bookinfo --show-labels
curl -I https://httpbin.org/status/200
```

## Implementation steps
Create a mesh-injected curl pod:

```bash
kubectl run egress-curl -n bookinfo --image=curlimages/curl --restart=Never -- sleep 3600
kubectl wait --for=condition=Ready pod/egress-curl -n bookinfo --timeout=120s
kubectl get pod egress-curl -n bookinfo -o jsonpath='{.spec.containers[*].name}{"\n"}'
```

Apply the `ServiceEntry`:

```bash
kubectl apply -f exercises/10-egress/manifests/httpbin-serviceentry.yaml
kubectl get serviceentry -n bookinfo
istioctl analyze -n bookinfo
```

Test egress:

```bash
kubectl exec -n bookinfo egress-curl -- curl -I https://httpbin.org/status/200
```

Expected: `HTTP/2 200` or `HTTP/1.1 200 OK`.

## Troubleshooting
If `kubectl exec ... -c curl` fails, check the container name:

```bash
kubectl get pod egress-curl -n bookinfo -o jsonpath='{.spec.containers[*].name}{"\n"}'
```

For a `kubectl run egress-curl ...` pod, the application container is usually named `egress-curl`, so you can omit `-c`.

## Cleanup
```bash
kubectl delete pod egress-curl -n bookinfo --ignore-not-found
kubectl delete serviceentry httpbin-egress -n bookinfo --ignore-not-found
```

## Architectural lessons
`ServiceEntry` adds external hosts to Istio's service registry. It does not by itself block or allow all external traffic unless mesh outbound policy is configured to require registry-only access.

## Self-assessment questions
1. What does `MESH_EXTERNAL` mean?
2. Why is DNS resolution used for `httpbin.org`?
3. What changes if outbound traffic policy is `REGISTRY_ONLY`?
