# Network Policies

This directory contains reusable Kubernetes `NetworkPolicy` examples for lab validation.

## Files

- `deny-all-bookinfo-ingress.yaml` - deny all ingress to pods in `bookinfo`
- `allow-istio-ingressgateway-to-bookinfo.yaml` - allow ingress gateway traffic to `bookinfo`

## Deny All Bookinfo Ingress

```bash
kubectl apply -f kubernetes/network-policies/deny-all-bookinfo-ingress.yaml
kubectl get networkpolicy -n bookinfo
```

Expected from an external test pod:

```text
curl: (28) Connection timed out
000
```

Cleanup:

```bash
kubectl delete -f kubernetes/network-policies/deny-all-bookinfo-ingress.yaml --ignore-not-found
```

## Allow Ingress Gateway

Apply after the deny policy if you want to preserve ingress gateway connectivity while blocking other sources:

```bash
kubectl apply -f kubernetes/network-policies/allow-istio-ingressgateway-to-bookinfo.yaml
```

This relies on the standard Kubernetes namespace label `kubernetes.io/metadata.name=istio-system` and the ingress gateway pod label `app=istio-ingressgateway`.

## Verification

```bash
kubectl get networkpolicy -n bookinfo
kubectl describe networkpolicy -n bookinfo
curl -I http://172.22.0.240/productpage
```

## Cleanup

```bash
kubectl delete -f kubernetes/network-policies/allow-istio-ingressgateway-to-bookinfo.yaml --ignore-not-found
kubectl delete -f kubernetes/network-policies/deny-all-bookinfo-ingress.yaml --ignore-not-found
```
