# role: containerd

Installs and configures the container runtime used by kubelet.

## Tasks

- creates `/etc/apt/keyrings`
- adds the Docker APT repository
- installs pinned `containerd.io`
- generates `/etc/containerd/config.toml`
- sets `SystemdCgroup = true`
- enables and starts `containerd`

## Verify

```bash
containerd --version
grep 'SystemdCgroup = true' /etc/containerd/config.toml
systemctl is-active containerd
```

`SystemdCgroup = true` is required so kubelet and containerd use compatible
cgroup management.
