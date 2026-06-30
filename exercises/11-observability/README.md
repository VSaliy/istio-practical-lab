# Exercise 11: Observability

## Difficulty
Intermediate

## Estimated effort
60-120 minutes

## Learning objectives
- Install and inspect Istio sample observability add-ons.
- Generate Bookinfo traffic.
- Use Kiali, Prometheus, and Envoy access logs for validation.

## Prerequisites
- Bookinfo is reachable through ingress.
- `/tmp/istio-1.24.2/samples/addons` exists.

## Files used
- `/tmp/istio-1.24.2/samples/addons`
- `scripts/diagnostics/collect-cluster-diagnostics.sh`

## Environment checks
```bash
ls /tmp/istio-1.24.2/samples/addons
curl -I http://172.22.0.240/productpage
```

## Implementation steps
Install add-ons:

```bash
kubectl apply -f /tmp/istio-1.24.2/samples/addons/prometheus.yaml
kubectl apply -f /tmp/istio-1.24.2/samples/addons/grafana.yaml
kubectl apply -f /tmp/istio-1.24.2/samples/addons/kiali.yaml
kubectl apply -f /tmp/istio-1.24.2/samples/addons/jaeger.yaml
kubectl get pods -n istio-system
```

Generate traffic:

```bash
for i in {1..100}; do curl -s -o /dev/null http://172.22.0.240/productpage; done
```

Open Kiali through port-forward:

```bash
kubectl -n istio-system port-forward svc/kiali 20001:20001 --address 0.0.0.0
```

From Windows browser, open:

```text
http://172.22.0.10:20001/kiali
```

## Verification
```bash
istioctl proxy-status
istioctl analyze -A
kubectl logs -n istio-system deploy/istiod-1-24-2 --tail=50
kubectl logs -n bookinfo deploy/productpage-v1 -c istio-proxy --tail=20
```

Expected:
- proxies are `SYNCED`
- access logs show `GET /productpage 200`
- Kiali graph shows Bookinfo traffic after refresh

## Cleanup
```bash
kubectl delete -f /tmp/istio-1.24.2/samples/addons/jaeger.yaml --ignore-not-found
kubectl delete -f /tmp/istio-1.24.2/samples/addons/kiali.yaml --ignore-not-found
kubectl delete -f /tmp/istio-1.24.2/samples/addons/grafana.yaml --ignore-not-found
kubectl delete -f /tmp/istio-1.24.2/samples/addons/prometheus.yaml --ignore-not-found
```

## Architectural lessons
Observability must correlate Kubernetes health, Istio proxy state, telemetry, and user-facing requests. A healthy pod list alone is not enough.

## Self-assessment questions
1. What does Kiali show that `kubectl get pods` cannot?
2. Why should `istioctl analyze` be part of observability checks?
3. Which container emits Envoy access logs?
