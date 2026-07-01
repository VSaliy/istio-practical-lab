# Kubernetes Bootstrap

This directory contains kubeadm bootstrap configuration for the lab control plane.

## Files

- `kubeadm-config.yaml` - kubeadm cluster configuration used by `scripts/install/initialize-control-plane.sh`

## Run Order

Run node preparation on all VMs first:

```bash
sudo bash scripts/linux/prepare-node.sh
```

Initialize the control plane from the repository root:

```bash
bash scripts/install/initialize-control-plane.sh
```

The script:

- sources `versions.env`
- runs `sudo kubeadm init --config kubernetes/bootstrap/kubeadm-config.yaml --upload-certs`
- copies `/etc/kubernetes/admin.conf` into the current user's kubeconfig

## Worker Join

Generate the join command on `k8s-control-01`:

```bash
JOIN_CMD=$(bash scripts/install/generate-worker-join-command.sh)
echo "$JOIN_CMD"
```

Run the printed command on each worker with `sudo`.

If joining remotely through SSH and sudo asks for a password, allocate a TTY:

```bash
ssh -t vgs@172.22.0.11 "sudo $JOIN_CMD"
```

## Verification

```bash
kubectl get nodes -o wide
kubectl -n kube-system get pods
kubectl cluster-info
```

Expected:

- control plane is `Ready` after CNI is installed
- workers become `Ready` after joining and Calico rollout
- CoreDNS starts after pod networking is functional

## Troubleshooting

```bash
sudo systemctl status kubelet --no-pager
sudo journalctl -u kubelet -n 100 --no-pager
sudo crictl ps -a
kubectl get events -A --sort-by=.lastTimestamp
```

Common causes:

- swap was not disabled
- containerd cgroup driver does not use systemd
- pod CIDR does not match CNI configuration
- worker join token expired
