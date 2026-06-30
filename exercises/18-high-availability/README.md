# Exercise 18: High Availability

## Difficulty
Intermediate

## Estimated effort
60-120 minutes

## Learning objectives
- Scale Istio and application components without changing service URLs.
- Use `PodDisruptionBudget` to protect voluntary disruptions.
- Observe how Kubernetes replaces failed pods while Istio keeps routing to healthy endpoints.
- Distinguish lab HA from production HA.

## Architectural context
This lab runs one Kubernetes control plane and two workers. That is enough to test workload and Istio data-plane availability, but it is not a highly available Kubernetes control plane.

The exercise focuses on:
- multiple Bookinfo replicas
- multiple ingress gateway replicas
- revisioned `istiod` availability
- controlled pod deletion and recovery

## Prerequisites
- Exercises 01-17 completed.
- Bookinfo is reachable through MetalLB at `172.22.0.240`.
- Metrics Server is running.
- No deny-all `AuthorizationPolicy` or `NetworkPolicy` remains from earlier exercises.

## Files used
- `exercises/18-high-availability/manifests/bookinfo-pdbs.yaml`
- `exercises/18-high-availability/manifests/istio-pdbs.yaml`

## Environment checks
Run on `k8s-control-01` from the repository root:

```bash
kubectl get nodes -o wide
kubectl get pods -n bookinfo
kubectl get deploy -n istio-system
curl -I http://172.22.0.240/productpage
```

Expected:
- all nodes are `Ready`
- Bookinfo pods are `2/2 Running`
- `istiod-1-29-5` and `istio-ingressgateway` are available
- ingress returns `HTTP/1.1 200 OK`

## Implementation steps
Scale the ingress gateway:

```bash
kubectl scale deployment istio-ingressgateway -n istio-system --replicas=2
kubectl rollout status deployment/istio-ingressgateway -n istio-system --timeout=180s
```

Scale selected Bookinfo services:

```bash
kubectl scale deployment productpage-v1 reviews-v1 -n bookinfo --replicas=2
kubectl rollout status deployment/productpage-v1 -n bookinfo --timeout=180s
kubectl rollout status deployment/reviews-v1 -n bookinfo --timeout=180s
```

Apply disruption budgets:

```bash
kubectl apply -f exercises/18-high-availability/manifests/bookinfo-pdbs.yaml
kubectl apply -f exercises/18-high-availability/manifests/istio-pdbs.yaml
```

## Expected output
```bash
kubectl get deploy -n bookinfo
kubectl get deploy -n istio-system istio-ingressgateway
kubectl get pdb -A
```

Expected:
- `productpage-v1` shows `2/2`
- `reviews-v1` shows `2/2`
- `istio-ingressgateway` shows `2/2`
- PDBs show at least one disruption allowed when replicas are sufficient

## Failure experiments
Delete one Bookinfo pod and watch Kubernetes replace it:

```bash
kubectl delete pod -n bookinfo -l app=productpage --wait=false
kubectl get pods -n bookinfo -w
```

In another terminal, send repeated requests:

```bash
for i in {1..20}; do
  curl -sS -o /dev/null -w "%{http_code} %{time_total}\n" http://172.22.0.240/productpage
  sleep 1
done
```

Expected: requests continue returning `200` while a replacement pod becomes ready.

Delete one ingress gateway pod:

```bash
kubectl delete pod -n istio-system -l app=istio-ingressgateway --wait=false
kubectl rollout status deployment/istio-ingressgateway -n istio-system --timeout=180s
curl -I http://172.22.0.240/productpage
```

Expected: ingress remains available or recovers quickly.

## Verification
```bash
kubectl get deploy -n bookinfo
kubectl get deploy -n istio-system
kubectl get pdb -A
kubectl top pods -n bookinfo
curl -I http://172.22.0.240/productpage
istioctl analyze -n bookinfo
```

## Troubleshooting
- If traffic returns `503`, check pod readiness and endpoints:

```bash
kubectl get endpoints -n bookinfo productpage
kubectl describe pod -n bookinfo -l app=productpage
```

- If PDBs show `0` allowed disruptions, verify replica counts:

```bash
kubectl get deploy -n bookinfo
kubectl get deploy -n istio-system istio-ingressgateway
```

## Cleanup
Return to the one-replica lab baseline:

```bash
kubectl delete -f exercises/18-high-availability/manifests/bookinfo-pdbs.yaml --ignore-not-found
kubectl delete -f exercises/18-high-availability/manifests/istio-pdbs.yaml --ignore-not-found
kubectl scale deployment productpage-v1 reviews-v1 -n bookinfo --replicas=1
kubectl scale deployment istio-ingressgateway -n istio-system --replicas=1
kubectl rollout status deployment/productpage-v1 -n bookinfo --timeout=180s
kubectl rollout status deployment/reviews-v1 -n bookinfo --timeout=180s
kubectl rollout status deployment/istio-ingressgateway -n istio-system --timeout=180s
curl -I http://172.22.0.240/productpage
```

## Architectural lessons
HA is layered. Multiple application replicas help only when the service has healthy endpoints. Multiple ingress gateway replicas help only when the load balancer can route to healthy nodes. A single Kubernetes control plane remains a lab limitation.

## Production considerations
- Use at least three control-plane nodes for Kubernetes HA.
- Run multiple ingress gateways across failure domains.
- Use anti-affinity and topology spread constraints.
- Configure PDBs only after verifying replica counts and upgrade behavior.

## Self-assessment questions
1. Which layer stayed available when a Bookinfo pod was deleted?
2. Why does a PDB not protect against all failures?
3. What part of this Hyper-V lab is still not highly available?
