# role: common

Prepares operating-system settings required before kubeadm can admit a node.

## Tasks

- installs baseline APT packages
- disables active swap
- comments swap entries in `/etc/fstab`
- persists and loads `overlay`
- persists and loads `br_netfilter`
- writes Kubernetes CRI sysctls
- applies sysctl settings through a handler

## Verify

```bash
swapon --show
lsmod | grep -E 'overlay|br_netfilter'
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.bridge.bridge-nf-call-ip6tables
sysctl net.ipv4.ip_forward
```
