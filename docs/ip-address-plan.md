# IP Address Plan

| Component | CIDR / Address | Notes |
|---|---|---|
| Hyper-V lab subnet | 172.22.0.0/24 | WinNAT managed |
| Windows host vNIC | 172.22.0.1 | Gateway for VMs |
| k8s-control-01 | 172.22.0.10 | API endpoint node |
| k8s-worker-01 | 172.22.0.11 | worker |
| k8s-worker-02 | 172.22.0.12 | worker |
| Kubernetes Pod CIDR | 10.244.0.0/16 | Calico |
| Kubernetes Service CIDR | 10.96.0.0/12 | kubeadm default-style |
| MetalLB pool | 172.22.0.240-172.22.0.250 | must not overlap static IP or DHCP |
