# Kubernetes Layer

This directory contains the Kubernetes substrate for the Istio practical lab. It covers kubeadm bootstrap, container networking, load-balancer integration, metrics, test workloads, storage notes, and backup boundaries.

## Layer Responsibilities

- Create a kubeadm cluster on the Hyper-V Ubuntu VMs.
- Use containerd as the CRI runtime.
- Provide pod networking through Calico.
- Provide `LoadBalancer` services through MetalLB.
- Provide resource metrics through Metrics Server.
- Provide small test workloads for validation and policy exercises.

The Kubernetes layer stops before Istio installation. Istio lives under `istio/` and application workloads live under `applications/`.

## Directory Map

| Path | Purpose |
| --- | --- |
| `bootstrap/` | kubeadm configuration and control-plane bootstrap context |
| `calico/` | Calico operator installation manifest and CNI notes |
| `metallb/` | MetalLB IP pool and L2 advertisement manifests |
| `metrics-server/` | Metrics Server install and Hyper-V kubelet TLS notes |
| `network-policies/` | Reusable NetworkPolicy examples for lab exercises |
| `test-workloads/` | Small pods used for connectivity and policy validation |
| `storage/` | Local VM disk and Kubernetes storage boundaries |
| `backup/` | Snapshot and backup guidance for this lab |

## Current Lab Assumptions

| Component | Value |
| --- | --- |
| Kubernetes | `1.31.2` |
| Runtime | `containerd 1.7.23` |
| CNI | Calico `3.29.0` |
| Load balancer | MetalLB `0.14.8` |
| Metrics | Metrics Server `0.7.2` |
| Node network | `172.22.0.0/24` lab network plus optional DHCP internet NIC |
| Pod CIDR | configured in `bootstrap/kubeadm-config.yaml` |
| MetalLB pool | `172.22.0.240-172.22.0.250` |

Check exact pinned versions in `versions.env`.

## Bootstrap Flow

Run on each node:

```bash
sudo bash scripts/linux/prepare-node.sh
```

Run on the control plane:

```bash
bash scripts/install/initialize-control-plane.sh
bash scripts/install/install-calico.sh
bash scripts/install/install-metrics-server.sh
bash scripts/install/install-metallb.sh
```

Generate worker join command on the control plane:

```bash
JOIN_CMD=$(bash scripts/install/generate-worker-join-command.sh)
echo "$JOIN_CMD"
```

Run the printed `sudo kubeadm join ...` command on each worker.

## Health Checks

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl -n calico-system get pods
kubectl -n metallb-system get pods
kubectl top nodes
```

Expected baseline:

- all nodes are `Ready`
- CoreDNS pods are `Running`
- Calico node pods are `Running`
- MetalLB controller and speakers are `Running`
- `kubectl top nodes` returns CPU and memory usage

## Validation Workloads

Use the reusable curl pod:

```bash
kubectl apply -f kubernetes/test-workloads/curl-pod.yaml
kubectl wait --for=condition=Ready pod/curl -n lab-test --timeout=120s
kubectl exec -n lab-test curl -- curl -sS https://kubernetes.default.svc
```

Cleanup:

```bash
kubectl delete namespace lab-test --ignore-not-found
```

## Failure Boundaries

- If nodes are `NotReady`, start with kubelet, containerd, and CNI.
- If pods are `Pending`, check CNI readiness, node resources, taints, and image pulls.
- If `LoadBalancer` services have no external IP, check MetalLB controller, speakers, IP pool, and L2 advertisement.
- If `kubectl top nodes` fails, check Metrics Server rollout and kubelet TLS flags.

## Diagnostics

```bash
bash scripts/diagnostics/collect-cluster-diagnostics.sh
```

The script writes a timestamped directory under `diagnostics/`.

## Production Notes

This Kubernetes layer is intentionally lab-oriented. It uses one control-plane node, local VM disks, and a small MetalLB L2 pool. Production clusters should use HA control planes, managed storage, external backup automation, node lifecycle automation, and explicit SLOs.
