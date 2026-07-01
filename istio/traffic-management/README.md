# Traffic Management

This layer contains Bookinfo routing examples for subsets and traffic splitting.

## Files

- `manifests/reviews-destination-rule.yaml`
- `manifests/reviews-v1-only.yaml`
- `manifests/reviews-v1-v3-50-50.yaml`

## Baseline

```bash
kubectl get pods -n bookinfo
kubectl get virtualservice,destinationrule -n bookinfo
curl -I http://172.22.0.240/productpage
```

## Route all reviews traffic to v1

```bash
kubectl apply -f istio/traffic-management/manifests/reviews-destination-rule.yaml
kubectl apply -f istio/traffic-management/manifests/reviews-v1-only.yaml
istioctl analyze -n bookinfo
```

Verify by refreshing `/productpage`. Reviews should consistently use the v1 behavior.

## Split reviews traffic between v1 and v3

```bash
kubectl apply -f istio/traffic-management/manifests/reviews-v1-v3-50-50.yaml
istioctl analyze -n bookinfo
```

Refresh several times. Traffic should alternate statistically between v1 and v3.

## Cleanup

```bash
kubectl delete virtualservice reviews -n bookinfo --ignore-not-found
kubectl delete destinationrule reviews -n bookinfo --ignore-not-found
istioctl analyze -n bookinfo
curl -I http://172.22.0.240/productpage
```
