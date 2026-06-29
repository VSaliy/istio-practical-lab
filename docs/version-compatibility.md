# Version Compatibility

Selected and pinned in `versions.env`.

| Component | Version | Compatibility note |
|---|---|---|
| Ubuntu | 24.04.2 LTS | ships kernel/container features suitable for containerd + kubelet |
| Kubernetes | 1.31.2 | supported by Istio 1.24 and Calico 3.29 |
| Istio | 1.24.2 | supports Kubernetes 1.29-1.32 range |
| Calico | 3.29.0 | supports Kubernetes 1.31 |
| Gateway API | 1.2.1 | compatible CRDs with Istio 1.24 examples |

Decision summary:

- Kubernetes 1.31.2 selected as stable baseline for kubeadm labs.
- Istio 1.24.2 chosen for revision-based upgrade and ambient exercises.
- Calico 3.29.0 chosen for current kernel/API support and VXLAN configurability.
