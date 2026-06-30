# Exercise 13: Istio CNI

## Difficulty
Intermediate

## Estimated effort
45-90 minutes

## Learning objectives
- Identify whether this lab uses sidecar init containers or Istio CNI.
- Understand why Istio CNI changes pod startup and privilege boundaries.
- Decide when not to retrofit CNI into a healthy lab cluster.

## Prerequisites
- Bookinfo is running with sidecars.

## Files used
- `istio/cni/README.md`
- `istio/installation/profiles/lab-profile.yaml`

## Environment checks
```bash
kubectl get pods -n bookinfo
kubectl get daemonset -A | grep -i cni || true
```

## Implementation steps
Inspect an injected pod:

```bash
POD=$(kubectl get pod -n bookinfo -l app=productpage -o jsonpath='{.items[0].metadata.name}')
kubectl describe pod "$POD" -n bookinfo | grep -A10 "Init Containers:"
```

Expected:
- `istio-init` is present
- arguments include `istio-iptables`

Inspect Istio system daemonsets:

```bash
kubectl get daemonset -n istio-system
kubectl get daemonset -A | grep -i istio
```

Expected for this lab: no Istio CNI daemonset.

## Verification
```bash
kubectl get pod "$POD" -n bookinfo -o jsonpath='{.spec.initContainers[*].name}{"\n"}'
kubectl get pod "$POD" -n bookinfo -o jsonpath='{.spec.containers[*].name}{"\n"}'
```

Expected:
- init container includes `istio-init`
- containers include application and `istio-proxy`

## Failure experiment
Do not install Istio CNI into this active sidecar lab as a casual experiment. Treat this exercise as inspection-only unless you reset the cluster or create a separate cluster specifically for CNI.

## Cleanup
No cleanup is required.

## Architectural lessons
Without Istio CNI, each injected pod uses an init container to configure traffic redirection. With Istio CNI, node-level CNI components handle that setup.

## Self-assessment questions
1. What is the purpose of `istio-init`?
2. Why can Istio CNI reduce pod privilege requirements?
3. Why is CNI migration risky on an already-running lab?
