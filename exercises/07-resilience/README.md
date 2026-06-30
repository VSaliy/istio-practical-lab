# Exercise 07: Resilience

## Difficulty
Intermediate

## Estimated effort
60-120 minutes

## Learning objectives
- Inject delays and aborts with Istio `VirtualService`.
- Observe user-facing behavior when a dependency is slow or failing.
- Restore baseline routing after resilience experiments.

## Prerequisites
- Bookinfo is healthy.
- Exercise 06 concepts understood.

## Files used
- `exercises/07-resilience/manifests/ratings-delay.yaml`
- `exercises/07-resilience/manifests/ratings-abort.yaml`

## Environment checks
```bash
kubectl get pods -n bookinfo
curl -I http://172.22.0.240/productpage
```

## Implementation steps
Apply a delay to `ratings`:

```bash
kubectl apply -f exercises/07-resilience/manifests/ratings-delay.yaml
time curl -s -o /dev/null -w "%{http_code}\n" http://172.22.0.240/productpage
```

Expected: request is slower but should still return an HTTP code.

Replace delay with an abort:

```bash
kubectl apply -f exercises/07-resilience/manifests/ratings-abort.yaml
curl -s http://172.22.0.240/productpage | head
```

Expected: productpage remains available, but reviews/ratings behavior is degraded.

## Verification
```bash
kubectl get virtualservice ratings -n bookinfo -o yaml
istioctl analyze -n bookinfo
curl -I http://172.22.0.240/productpage
```

## Failure experiment
Increase fault percentage to `100` in either manifest and reapply. Confirm the application remains reachable but dependency output changes.

## Cleanup
```bash
kubectl delete virtualservice ratings -n bookinfo --ignore-not-found
curl -I http://172.22.0.240/productpage
```

## Architectural lessons
Resilience policies should be tested from the user's path, not only from pod status. Pods can be healthy while traffic behavior is intentionally degraded.

## Production considerations
- Use faults only in controlled test environments.
- Pair retries/timeouts with service objectives and dependency capacity.
- Keep rollback commands ready before applying policy changes.

## Self-assessment questions
1. What is the difference between a delay and an abort fault?
2. Why did productpage remain reachable when ratings was degraded?
3. Which command restores baseline routing?
