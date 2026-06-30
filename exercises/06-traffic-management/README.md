# Exercise 06: Traffic Management

## Difficulty
Intermediate

## Estimated effort
60-120 minutes

## Learning objectives
- Use `DestinationRule` subsets.
- Route all traffic to one service version.
- Split traffic between two versions.

## Prerequisites
- Bookinfo pods are `2/2 Running`.
- Ingress returns `200 OK`.

## Files used
- `exercises/06-traffic-management/manifests/destination-rule-reviews.yaml`
- `exercises/06-traffic-management/manifests/virtual-service-reviews-v1.yaml`
- `exercises/06-traffic-management/manifests/virtual-service-reviews-50-v3.yaml`

## Environment checks
```bash
kubectl get pods -n bookinfo -l app=reviews
curl -I http://172.22.0.240/productpage
```

## Implementation steps
Create subsets for the `reviews` service:

```bash
kubectl apply -f exercises/06-traffic-management/manifests/destination-rule-reviews.yaml
```

Route all reviews traffic to v1:

```bash
kubectl apply -f exercises/06-traffic-management/manifests/virtual-service-reviews-v1.yaml
```

Generate traffic:

```bash
for i in {1..10}; do curl -s http://172.22.0.240/productpage | grep -o "glyphicon-star" | wc -l; done
```

Expected: `0` stars because `reviews-v1` does not call ratings.

Split traffic between v1 and v3:

```bash
kubectl apply -f exercises/06-traffic-management/manifests/virtual-service-reviews-50-v3.yaml
```

Generate traffic again:

```bash
for i in {1..20}; do curl -s http://172.22.0.240/productpage | grep -o "glyphicon-star" | wc -l; done
```

Expected: mixed output, with some requests showing stars from `reviews-v3`.

## Verification
```bash
kubectl get destinationrule,virtualservice -n bookinfo
istioctl analyze -n bookinfo
curl -I http://172.22.0.240/productpage
```

## Failure experiment
Point traffic to a nonexistent subset and observe `503`, then restore:

```bash
kubectl apply -n bookinfo -f - <<'EOF'
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  name: reviews
spec:
  hosts:
  - reviews
  http:
  - route:
    - destination:
        host: reviews
        subset: missing
EOF
curl -I http://172.22.0.240/productpage
kubectl apply -f exercises/06-traffic-management/manifests/virtual-service-reviews-v1.yaml
```

## Cleanup
```bash
kubectl delete virtualservice reviews -n bookinfo --ignore-not-found
kubectl delete destinationrule reviews -n bookinfo --ignore-not-found
curl -I http://172.22.0.240/productpage
```

## Architectural lessons
Traffic policies are separate from Kubernetes Services. Services define discovery; Istio policies define routing behavior.

## Self-assessment questions
1. What field connects a `VirtualService` route to a `DestinationRule` subset?
2. Why can a bad subset produce `503` while pods are healthy?
3. How would you use weighted routing for a canary release?
