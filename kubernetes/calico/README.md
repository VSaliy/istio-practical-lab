# Calico

Calico provides pod networking and Kubernetes `NetworkPolicy` enforcement for this lab.

## Files

- `calico-installation.yaml` - local Calico operator/custom-resource installation material

## Install

Run from the repository root on `k8s-control-01`:

```bash
bash scripts/install/install-calico.sh
```

## Verification

```bash
kubectl get pods -n calico-system
kubectl get daemonset -n calico-system
kubectl get nodes -o wide
kubectl -n kube-system get pods -l k8s-app=kube-dns
```

Expected:

- `calico-node` daemonset has one ready pod per node
- `calico-kube-controllers` is `Running`
- CoreDNS is `Running`
- nodes are `Ready`

## Policy Test

Use Exercise 16 or the reusable manifest:

```bash
kubectl apply -f kubernetes/network-policies/deny-all-bookinfo-ingress.yaml
kubectl get networkpolicy -n bookinfo
```

Cleanup:

```bash
kubectl delete -f kubernetes/network-policies/deny-all-bookinfo-ingress.yaml --ignore-not-found
```

## Troubleshooting

```bash
kubectl describe pod -n calico-system -l k8s-app=calico-node
kubectl logs -n calico-system -l k8s-app=calico-node --tail=100
kubectl get ippools.crd.projectcalico.org -A
```

If pods are stuck in `ContainerCreating` or CoreDNS is `Pending`, inspect CNI first.
