# Exercise 05: Sidecar Injection

## Difficulty
Beginner

## Estimated effort
45-75 minutes

## Learning objectives
- Explain revision-based sidecar injection.
- Compare injected and non-injected pods.
- Safely recreate pods after changing namespace labels.

## Prerequisites
- Bookinfo is deployed.
- Istio revision is `1-24-2`.

## Files used
- `scripts/install/deploy-bookinfo.sh`
- `istio/installation/profiles/lab-profile.yaml`

## Environment checks
```bash
kubectl get ns bookinfo --show-labels
kubectl get pods -n bookinfo
```

Expected:
- `bookinfo` has `istio.io/rev=1-24-2`
- Bookinfo pods are `2/2 Running`

## Implementation steps
Inspect an injected pod:

```bash
POD=$(kubectl get pod -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}')
kubectl get pod "$POD" -n bookinfo -o jsonpath='{.spec.containers[*].name}{"\n"}'
kubectl describe pod "$POD" -n bookinfo | grep -A8 "Init Containers:"
```

Create a namespace without injection:

```bash
kubectl create namespace no-injection-test
kubectl run nginx -n no-injection-test --image=nginx --restart=Never
kubectl wait --for=condition=Ready pod/nginx -n no-injection-test --timeout=120s
kubectl get pod nginx -n no-injection-test -o jsonpath='{.spec.containers[*].name}{"\n"}'
```

Expected:

```text
nginx
```

Enable injection and recreate:

```bash
kubectl label namespace no-injection-test istio.io/rev=1-24-2
kubectl delete pod nginx -n no-injection-test
kubectl run nginx -n no-injection-test --image=nginx --restart=Never
kubectl wait --for=condition=Ready pod/nginx -n no-injection-test --timeout=120s
kubectl get pod nginx -n no-injection-test -o jsonpath='{.spec.containers[*].name}{"\n"}'
```

Expected:

```text
nginx istio-proxy
```

## Verification
```bash
kubectl get pod nginx -n no-injection-test
istioctl proxy-status | grep no-injection-test
```

## Failure experiment
Remove the label and create another pod:

```bash
kubectl label namespace no-injection-test istio.io/rev-
kubectl run nginx-plain -n no-injection-test --image=nginx --restart=Never
kubectl wait --for=condition=Ready pod/nginx-plain -n no-injection-test --timeout=120s
kubectl get pod nginx-plain -n no-injection-test -o jsonpath='{.spec.containers[*].name}{"\n"}'
```

Expected: only `nginx`.

## Cleanup
```bash
kubectl delete namespace no-injection-test
```

## Architectural lessons
Injection is decided when a pod is created. Changing namespace labels does not mutate existing pods.

## Self-assessment questions
1. Why does a pod need to be recreated after enabling injection?
2. What is the difference between `istio.io/rev` and legacy `istio-injection=enabled`?
3. Which container handles mesh traffic for the application?
