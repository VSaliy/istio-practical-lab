# Exercise 14: Ambient Mesh

## Difficulty
Advanced

## Estimated effort
45-90 minutes

## Learning objectives
- Compare sidecar mode and ambient mode.
- Identify why this lab is currently sidecar-based.
- Understand the components required for ambient mesh.

## Prerequisites
- Exercises 01-13 complete.
- Current cluster is healthy in sidecar mode.

## Files used
- `istio/ambient/README.md`
- `istio/installation/profiles/lab-profile.yaml`

## Environment checks
```bash
kubectl get pods -n istio-system
kubectl get pods -n bookinfo
kubectl get daemonset -A | grep -E "ztunnel|cni" || true
```

## Implementation steps
Confirm current sidecar mode:

```bash
kubectl get ns bookinfo --show-labels
kubectl get pod -n bookinfo -l app=productpage -o jsonpath='{.items[0].spec.containers[*].name}{"\n"}'
kubectl get pod -n bookinfo -l app=productpage -o jsonpath='{.items[0].spec.initContainers[*].name}{"\n"}'
```

Expected:
- namespace has `istio.io/rev=1-24-2`
- pod has `istio-proxy`
- pod has `istio-init`

Check for ambient components:

```bash
kubectl get pods -A | grep -E "ztunnel|waypoint" || true
kubectl get daemonset -A | grep ztunnel || true
```

Expected in this lab: no ambient dataplane components.

## Verification
```bash
curl -I http://172.22.0.240/productpage
istioctl proxy-status
```

## Failure experiment
Do not mix ambient installation changes into this sidecar lab unless the exercise explicitly asks for a cluster reset. Ambient requires a different dataplane model and additional components such as ztunnel, and later exercises assume the sidecar Bookinfo baseline.

## Cleanup
No cleanup is required.

## Architectural lessons
Sidecar mode puts Envoy in every pod. Ambient mode separates L4 node-level secure overlay from optional L7 waypoint proxies.

## Self-assessment questions
1. What component provides the ambient L4 dataplane?
2. Why does sidecar mode show `2/2` pods?
3. Why should this lab avoid switching dataplane models midstream?
