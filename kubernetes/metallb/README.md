# MetalLB

MetalLB provides `LoadBalancer` service support for the Hyper-V lab network.

## Files

- `ipaddresspool.yaml` - address pool for lab `LoadBalancer` services
- `l2advertisement.yaml` - L2 advertisement for the pool

## Install

```bash
bash scripts/install/install-metallb.sh
```

## Verification

```bash
kubectl get pods -n metallb-system
kubectl get ipaddresspools -n metallb-system
kubectl get l2advertisements -n metallb-system
kubectl get svc -n istio-system istio-ingressgateway
```

Expected:

- controller is `Running`
- one speaker pod is running per node
- pool includes `172.22.0.240-172.22.0.250`
- Istio ingress gateway receives `172.22.0.240`

## Connectivity Check

```bash
curl -I http://172.22.0.240/productpage
```

Expected after Istio and Bookinfo are installed:

```text
HTTP/1.1 200 OK
```

## Troubleshooting

```bash
kubectl describe svc -n istio-system istio-ingressgateway
kubectl logs -n metallb-system deploy/controller --tail=100
kubectl logs -n metallb-system -l component=speaker --tail=100
```

Common causes:

- address pool overlaps with another host route
- Hyper-V switch/NAT not configured as expected
- speakers are not running on all nodes
