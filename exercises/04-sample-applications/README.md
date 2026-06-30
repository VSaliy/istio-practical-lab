# Exercise 04: Sample Applications

## Difficulty
Beginner

## Estimated effort
45-90 minutes

## Learning objectives
- Deploy the Istio Bookinfo sample application.
- Understand the service graph used by later exercises.
- Verify application health through both cluster-internal and ingress paths.

## Prerequisites
- Exercises 01-03 complete.
- Istio installed with revision `1-24-2`.

## Files used
- `scripts/install/deploy-bookinfo.sh`
- `applications/bookinfo/README.md`
- Istio sample manifests downloaded under `/tmp/istio-1.24.2`

## Environment checks
```bash
kubectl get pods -n istio-system
istioctl version
```

## Implementation steps
Deploy Bookinfo:

```bash
bash scripts/install/deploy-bookinfo.sh
```

Wait for readiness:

```bash
kubectl wait --for=condition=Ready pod -l app=productpage -n bookinfo --timeout=180s
kubectl wait --for=condition=Ready pod -l app=details -n bookinfo --timeout=180s
kubectl wait --for=condition=Ready pod -l app=ratings -n bookinfo --timeout=180s
kubectl wait --for=condition=Ready pod -l app=reviews -n bookinfo --timeout=180s
```

## Commands
```bash
kubectl get ns bookinfo --show-labels
kubectl get pods -n bookinfo
kubectl get svc -n bookinfo
kubectl get gateway,virtualservice -n bookinfo
curl -I http://172.22.0.240/productpage
```

## Expected output
- namespace `bookinfo` has `istio.io/rev=1-24-2`
- Bookinfo pods show `2/2 Running`
- ingress returns `HTTP/1.1 200 OK`

## Verification
```bash
curl -s http://172.22.0.240/productpage | grep -i "Simple Bookstore"
kubectl exec -n bookinfo deploy/productpage-v1 -c productpage -- curl -sS http://details:9080/details/0
```

## Failure experiment
Scale one backend to zero and observe productpage degradation:

```bash
kubectl scale deployment ratings-v1 -n bookinfo --replicas=0
curl -s http://172.22.0.240/productpage | head
kubectl scale deployment ratings-v1 -n bookinfo --replicas=1
kubectl rollout status deployment/ratings-v1 -n bookinfo --timeout=180s
```

## Cleanup
Keep Bookinfo installed for later exercises. To fully remove it:

```bash
kubectl delete namespace bookinfo
```

## Architectural lessons
Bookinfo provides stable services and multiple versions of `reviews`, which makes it useful for traffic shifting, policy, and resilience experiments.

## Self-assessment questions
1. Which Bookinfo service has multiple versions?
2. Why do Bookinfo pods show `2/2` containers?
3. Which Istio resources expose `/productpage` through the ingress gateway?
