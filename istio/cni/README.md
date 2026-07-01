# Istio CNI

Istio CNI moves sidecar traffic redirection out of the `istio-init` container and into a node-level CNI plugin. This is useful in restricted clusters where application pods should not need elevated init-container privileges.

## Verification

Check whether Istio CNI is installed:

```bash
kubectl get daemonset -n istio-system | grep cni
kubectl get pods -n istio-system | grep cni
```

Check whether Bookinfo pods still have an `istio-init` container:

```bash
kubectl describe pod -n bookinfo -l app=productpage | grep -A8 "Init Containers:"
```

With CNI enabled for injected pods, new pods should not need the `istio-init` iptables init container.

## Install note

In this lab, prefer exercising CNI separately from the standard sidecar install. Do not leave old CNI components running after an upgrade unless they are upgraded with the active Istio revision.

## Cleanup old CNI

If an old CNI daemonset remains after a sidecar-only upgrade:

```bash
kubectl delete daemonset istio-cni-node -n istio-system --ignore-not-found
```

Verify Bookinfo still works:

```bash
curl -I http://172.22.0.240/productpage
```
