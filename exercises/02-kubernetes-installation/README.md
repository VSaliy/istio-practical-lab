# Exercise 02: Kubernetes Installation

## Difficulty
Intermediate

## Estimated effort
120-180 minutes

## Learning objectives
- Prepare Ubuntu nodes for kubeadm + containerd
- Initialize control plane and join workers
- Install Calico, Metrics Server, and basic cluster add-ons

## Architectural context
The cluster uses kubeadm, containerd, and Calico VXLAN with explicit MTU for Hyper-V compatibility.

## Prerequisites
- Exercise 01 complete
- SSH access to all nodes

## Files used
- `scripts/linux/prepare-node.sh`
- `scripts/install/install-containerd.sh`
- `scripts/install/install-kubernetes-packages.sh`
- `kubernetes/bootstrap/kubeadm-config.yaml`

## Environment checks
```bash
LAB_USER="${LAB_USER:-ubuntu}"
ssh "${LAB_USER}@172.22.0.10" 'hostname && ip a'
```

## Implementation steps
1. Prepare each node.
2. Initialize control plane.
3. Join workers.
4. Install Calico and Metrics Server.

## Commands
```bash
sudo bash scripts/linux/prepare-node.sh
bash scripts/install/initialize-control-plane.sh
JOIN_CMD=$(bash scripts/install/generate-worker-join-command.sh)
LAB_USER="${LAB_USER:-ubuntu}"
ssh -t "${LAB_USER}@172.22.0.11" "sudo $JOIN_CMD"
ssh -t "${LAB_USER}@172.22.0.12" "sudo $JOIN_CMD"
bash scripts/install/install-calico.sh
bash scripts/install/install-metrics-server.sh
```

## Expected output
- all nodes `Ready`
- CoreDNS running
- `kubectl top nodes` returns metrics

## Verification
```bash
kubectl get nodes -o wide
kubectl -n kube-system get pods
kubectl top nodes
```

## Failure experiments
- Keep swap enabled and observe kubelet errors.
- Set incorrect pod CIDR and observe CNI failures.

## Troubleshooting
Use `scripts/diagnostics/collect-cluster-diagnostics.sh` then inspect kubelet logs.

## Cleanup
```bash
bash scripts/reset/reset-node.sh --confirm-reset
```

## Architectural lessons
Small host-level mismatches (swap, sysctl, cgroup driver) create major control-plane instability.

## Production considerations
Use immutable node images and automated conformance checks for consistent bootstrap.

## Self-assessment questions
1. Why is `SystemdCgroup=true` required here?
2. How does pod CIDR relate to Calico IP pool?
