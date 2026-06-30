# Exercise 19: Performance

## Difficulty
Intermediate

## Estimated effort
60-120 minutes

## Learning objectives
- Establish a simple latency and throughput baseline for Bookinfo.
- Use Metrics Server to identify hot pods during load.
- Compare single-replica and scaled-replica behavior.
- Understand the limits of ad hoc lab load testing.

## Architectural context
Bookinfo traffic enters through the Istio ingress gateway, reaches `productpage`, and fans out to `details`, `ratings`, and one `reviews` version. Istio sidecars add observability and policy enforcement but also consume CPU and memory.

This exercise uses lightweight HTTP load and `kubectl top` rather than a full benchmark suite.

## Prerequisites
- Exercises 01-18 completed.
- Metrics Server is installed and `kubectl top nodes` works.
- Bookinfo ingress returns `HTTP/1.1 200 OK`.
- Traffic-management experiments are cleaned up unless intentionally being tested.

## Files used
- `exercises/19-performance/manifests/bookinfo-load-job.yaml`

## Environment checks
```bash
kubectl top nodes
kubectl top pods -n bookinfo
kubectl get pods -n bookinfo
curl -I http://172.22.0.240/productpage
```

Expected:
- metrics are returned
- Bookinfo pods are `2/2 Running`
- ingress returns `200`

## Implementation steps
Run a small local latency sample:

```bash
for i in {1..20}; do
  curl -sS -o /dev/null -w "%{http_code} %{time_total}\n" http://172.22.0.240/productpage
done
```

Run concurrent requests from the control-plane node:

```bash
seq 1 100 | xargs -n1 -P10 -I{} curl -sS -o /dev/null -w "%{http_code} %{time_total}\n" http://172.22.0.240/productpage
```

Run an in-cluster load job:

```bash
kubectl apply -f exercises/19-performance/manifests/bookinfo-load-job.yaml
kubectl wait --for=condition=Complete job/bookinfo-load -n bookinfo --timeout=180s
kubectl logs job/bookinfo-load -n bookinfo
```

The load job disables sidecar injection so the Job can exit after the curl loop completes.

Watch metrics while load is running:

```bash
watch -n 2 'kubectl top nodes && echo && kubectl top pods -n bookinfo && echo && kubectl top pods -n istio-system'
```

## Expected output
- HTTP status codes should be mostly or entirely `200`.
- `kubectl top pods -n bookinfo` should show which service consumes the most CPU.
- `productpage` and `reviews` commonly become the interesting pods under this workload.

## Scaling experiment
Scale productpage and reviews:

```bash
kubectl scale deployment productpage-v1 reviews-v1 -n bookinfo --replicas=2
kubectl rollout status deployment/productpage-v1 -n bookinfo --timeout=180s
kubectl rollout status deployment/reviews-v1 -n bookinfo --timeout=180s
```

Run the same load again:

```bash
kubectl delete job bookinfo-load -n bookinfo --ignore-not-found
kubectl apply -f exercises/19-performance/manifests/bookinfo-load-job.yaml
kubectl wait --for=condition=Complete job/bookinfo-load -n bookinfo --timeout=180s
kubectl top pods -n bookinfo
```

Compare CPU distribution and response times to the baseline.

## Verification
```bash
kubectl get job bookinfo-load -n bookinfo
kubectl logs job/bookinfo-load -n bookinfo
kubectl top nodes
kubectl top pods -n bookinfo
curl -I http://172.22.0.240/productpage
```

## Failure experiments
Temporarily reduce productpage to one replica and run concurrent requests:

```bash
kubectl scale deployment productpage-v1 -n bookinfo --replicas=1
kubectl rollout status deployment/productpage-v1 -n bookinfo --timeout=180s
seq 1 100 | xargs -n1 -P20 -I{} curl -sS -o /dev/null -w "%{http_code} %{time_total}\n" http://172.22.0.240/productpage
```

Observe whether latency rises or errors appear.

## Troubleshooting
- If the load job cannot pull `curlimages/curl`, verify node internet access.
- If metrics are missing, check Metrics Server:

```bash
kubectl get pods -n kube-system | grep metrics-server
kubectl top nodes
```

- If response codes are `503`, check Bookinfo pods and Istio routes:

```bash
kubectl get pods -n bookinfo
istioctl analyze -n bookinfo
```

## Cleanup
```bash
kubectl delete job bookinfo-load -n bookinfo --ignore-not-found
kubectl scale deployment productpage-v1 reviews-v1 -n bookinfo --replicas=1
kubectl rollout status deployment/productpage-v1 -n bookinfo --timeout=180s
kubectl rollout status deployment/reviews-v1 -n bookinfo --timeout=180s
curl -I http://172.22.0.240/productpage
```

## Architectural lessons
Performance work needs a repeatable baseline. The useful outcome in this lab is not a production benchmark; it is learning how to correlate ingress latency, pod CPU, memory, replica count, and Istio sidecar overhead.

## Production considerations
- Use dedicated load tools such as k6, Fortio, or hey for real testing.
- Run tests from outside the cluster and from inside the cluster.
- Define SLOs before tuning.
- Record p50, p95, p99, error rate, and saturation signals.

## Self-assessment questions
1. Which Bookinfo pod consumed the most CPU under load?
2. Did scaling replicas reduce latency or only spread CPU?
3. What metrics are missing from this simple test?
