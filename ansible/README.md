# Ansible Layer

Ansible automation is optional. It prepares Ubuntu nodes the same way as
`scripts/linux/prepare-node.sh`, then the Kubernetes control-plane and worker
join flow can continue with the existing `scripts/install` commands.

Use it after the three VMs are installed, reachable by SSH, and using the lab
addresses from `ansible/inventory.ini`.

## Scope

This layer configures every Kubernetes node with:

- baseline packages for HTTPS APT repositories
- Docker APT repository for `containerd.io`
- containerd with `SystemdCgroup = true`
- Kubernetes APT repository for the pinned Kubernetes minor version
- pinned `kubelet`, `kubeadm`, `kubectl`, and `crictl`
- disabled swap
- required kernel modules and sysctls for bridged pod networking

It does not run `kubeadm init`, `kubeadm join`, Calico, MetalLB, Istio, or
Bookinfo deployment. Those are intentionally left in the guided install scripts.

## Prerequisites

Run from a Linux shell that has Ansible installed. The easiest path is from
`k8s-control-01` after cloning this repository:

```bash
sudo apt update
sudo apt install -y ansible
cd ~/istio-practical-lab/ansible
```

If you run Ansible from Windows, use WSL or another Linux environment with SSH
access to `172.22.0.10`, `172.22.0.11`, and `172.22.0.12`.

## Inventory

Default inventory:

```ini
[k8s_control]
k8s-control-01 ansible_host=172.22.0.10

[k8s_workers]
k8s-worker-01 ansible_host=172.22.0.11
k8s-worker-02 ansible_host=172.22.0.12
```

The inventory assumes the same SSH username exists on all three VMs. Override it
at runtime if needed:

```bash
ansible-playbook site.yml -u vgs --ask-pass --ask-become-pass
```

## Run

Check connectivity first:

```bash
ansible all -m ping -u vgs --ask-pass
```

Apply node preparation:

```bash
ansible-playbook site.yml -u vgs --ask-pass --ask-become-pass
```

If SSH keys are configured:

```bash
ansible-playbook site.yml -u vgs
```

## Verify

Use the verification playbook:

```bash
ansible-playbook verify.yml -u vgs --ask-pass --ask-become-pass
```

Or check manually on each node:

```bash
swapon --show
lsmod | grep -E 'overlay|br_netfilter'
sysctl net.ipv4.ip_forward
containerd --version
crictl info
kubeadm version
kubectl version --client=true
```

Expected signals:

- `swapon --show` prints no swap devices
- `net.ipv4.ip_forward = 1`
- `crictl info` can talk to containerd
- kubeadm and kubectl match the version pinned in `group_vars/all.yml`

## Next Step

After the playbook succeeds, continue from the Kubernetes install layer:

```bash
cd ~/istio-practical-lab
bash scripts/install/initialize-control-plane.sh
JOIN_CMD=$(bash scripts/install/generate-worker-join-command.sh)
```

Run the generated `kubeadm join ...` command on each worker with `sudo`.
