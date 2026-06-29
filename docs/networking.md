# Networking

## Default topology

- Hyper-V internal switch: `IstioLabSwitch`
- Host vNIC: `172.22.0.1/24`
- NAT prefix: `172.22.0.0/24`
- VM static IPs from `172.22.0.10+`

## Why NAT by default

Internal switch with WinNAT gives a stable, isolated lab network while preserving outbound internet access for package installs.

## MTU guidance

Calico VXLAN adds overhead. Use explicit MTU in Calico config (`1450` in this lab) to avoid fragmentation and intermittent service failures.

Diagnostics for MTU issues:

- `ip link show | grep mtu`
- `kubectl -n kube-system logs ds/calico-node`
- `ping -M do -s 1472 <target>` from nodes
