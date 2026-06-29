# Architecture

## Layers

1. **Infrastructure**: Hyper-V internal switch + WinNAT + Ubuntu VMs
2. **Kubernetes**: kubeadm control plane, containerd runtime, Calico CNI, MetalLB L2
3. **Service mesh**: Istio control plane + sidecar/ambient data plane modes
4. **Applications**: Bookinfo and planned Spring microservices
5. **Validation**: smoke checks, diagnostics, and CI static analysis

## Kubernetes topology

```mermaid
flowchart TB
  cp[k8s-control-01\ncontrol-plane]
  w1[k8s-worker-01]
  w2[k8s-worker-02]
  cp --- w1
  cp --- w2
  cp --> istiod
  w1 --> app1[Bookinfo pods]
  w2 --> app2[Bookinfo pods]
```

## Istio control/data planes

```mermaid
flowchart LR
  istiod[istiod] -->|xDS/certs| envoy1[Envoy sidecar A]
  istiod -->|xDS/certs| envoy2[Envoy sidecar B]
  envoy1 <--> envoy2
```

## External-switch alternative

External vSwitch can be used instead of internal+NAT for direct LAN reachability, but it introduces DHCP dependency, possible corporate network policy conflicts, and reduced isolation for experimentation.
