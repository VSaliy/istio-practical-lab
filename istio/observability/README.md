# Observability

This layer contains telemetry notes and dashboard access commands.

## Files

- `manifests/bookinfo-access-logging.yaml`

## Dashboard access

Prometheus:

```bash
kubectl port-forward svc/prometheus -n istio-system 9090:9090
```

Kiali:

```bash
kubectl port-forward svc/kiali -n istio-system 20001:20001
```

Grafana:

```bash
kubectl port-forward svc/grafana -n istio-system 3000:3000
```

Jaeger:

```bash
kubectl port-forward svc/tracing -n istio-system 16686:80
```

## Access logging

Enable namespace-scoped access logging for Bookinfo:

```bash
kubectl apply -f istio/observability/manifests/bookinfo-access-logging.yaml
kubectl logs -n bookinfo -l app=productpage -c istio-proxy --tail=20
```

Generate traffic:

```bash
for i in {1..5}; do curl -sS -o /dev/null http://172.22.0.240/productpage; done
kubectl logs -n bookinfo -l app=productpage -c istio-proxy --tail=20
```

## Verification

```bash
kubectl get telemetry -n bookinfo
istioctl analyze -n bookinfo
```

## Cleanup

```bash
kubectl delete telemetry bookinfo-access-logging -n bookinfo --ignore-not-found
```
