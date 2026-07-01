# Istio Layer

This directory contains reusable Istio installation, traffic, security, observability, upgrade, and advanced-mode materials for the lab.

Use `exercises/` for guided walkthroughs. Use this `istio/` layer as the reference library of manifests and operational notes.

## Layer map

- `installation/`: install paths and the lab `IstioOperator` profile.
- `gateways/`: classic Istio `Gateway` and ingress `VirtualService` resources.
- `gateway-api/`: Kubernetes Gateway API examples.
- `traffic-management/`: routing, subsets, and traffic shifting examples.
- `resilience/`: timeout and fault-injection examples.
- `security/`: mTLS and authorization policy examples.
- `egress/`: external service access examples.
- `observability/`: telemetry and dashboard access notes.
- `cni/`: Istio CNI verification and cleanup notes.
- `ambient/`: ambient mesh verification and lab caveats.
- `multi-tenancy/`: namespace and tenant isolation examples.
- `performance/`: lightweight load and metrics examples.
- `upgrades/`: revision-based upgrade runbook.

## Baseline commands

Run from `k8s-control-01`:

```bash
kubectl get nodes
kubectl get pods -A
kubectl get ns bookinfo default --show-labels
istioctl analyze -A
curl -I http://172.22.0.240/productpage
```

Expected:
- nodes are `Ready`
- Bookinfo pods are `2/2 Running`
- active application namespaces are labeled with the intended Istio revision
- Bookinfo ingress returns `HTTP/1.1 200 OK`

## Applying layer resources

Most manifests are safe lab examples and can be applied directly:

```bash
kubectl apply -f istio/<module>/manifests/<file>.yaml
```

Always verify after applying:

```bash
istioctl analyze -n bookinfo
curl -I http://172.22.0.240/productpage
```

Clean up module-specific resources before moving to the next unrelated exercise.
