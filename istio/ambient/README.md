# Ambient Mesh

Ambient mesh uses node-level `ztunnel` and optional waypoint proxies instead of sidecar proxies for all workloads.

## Lab caveat

This repository's main path uses classic sidecar mode. Ambient materials are for inspection and comparison. Do not mix old ambient components with a newer sidecar revision unless you intentionally upgrade ambient components too.

## Verification

Check for ambient components:

```bash
kubectl get daemonset -n istio-system | grep ztunnel
kubectl get pods -n istio-system | grep ztunnel
istioctl proxy-status
```

Check namespace labels:

```bash
kubectl get ns --show-labels | grep 'istio.io/dataplane-mode'
```

## Enable ambient for a test namespace

Use a separate namespace, not `bookinfo`, unless the exercise explicitly says so:

```bash
kubectl create namespace ambient-test
kubectl label namespace ambient-test istio.io/dataplane-mode=ambient
```

## Cleanup

```bash
kubectl delete namespace ambient-test --ignore-not-found
```

If old ambient components remain after an upgrade and sidecar mode is the desired final state:

```bash
kubectl delete daemonset ztunnel -n istio-system --ignore-not-found
```
