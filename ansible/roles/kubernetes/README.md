# role: kubernetes

Installs the kubeadm toolchain used by this lab.

## Tasks

- adds the Kubernetes APT repository for the pinned minor version
- installs pinned `kubelet`, `kubeadm`, and `kubectl`
- marks Kubernetes packages as held
- downloads and installs pinned `crictl`
- writes `/etc/crictl.yaml` for containerd

## Verify

```bash
kubeadm version
kubectl version --client=true
apt-mark showhold | grep -E 'kubelet|kubeadm|kubectl'
crictl info
```

This role prepares the tools only. It does not initialize or join the cluster.
