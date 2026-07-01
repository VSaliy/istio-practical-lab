# Resilience

This layer contains timeout and fault-injection examples for Bookinfo.

## Files

- `manifests/ratings-timeout.yaml`
- `manifests/ratings-delay.yaml`
- `manifests/ratings-abort.yaml`

## Timeout example

```bash
kubectl apply -f istio/resilience/manifests/ratings-timeout.yaml
istioctl analyze -n bookinfo
curl -I http://172.22.0.240/productpage
```

## Fault injection examples

Add delay:

```bash
kubectl apply -f istio/resilience/manifests/ratings-delay.yaml
```

Add abort:

```bash
kubectl apply -f istio/resilience/manifests/ratings-abort.yaml
```

Verify with repeated requests:

```bash
for i in {1..10}; do curl -sS -o /dev/null -w "%{http_code} %{time_total}\n" http://172.22.0.240/productpage; done
```

## Cleanup

```bash
kubectl delete virtualservice ratings -n bookinfo --ignore-not-found
istioctl analyze -n bookinfo
curl -I http://172.22.0.240/productpage
```
